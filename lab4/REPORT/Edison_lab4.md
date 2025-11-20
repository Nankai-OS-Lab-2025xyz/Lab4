# 操作系统 Lab4 实验报告：内核线程管理

## 实验目的

- 了解内核线程创建/执行的管理过程。
- 了解内核线程的切换和基本调度过程。
- 掌握进程控制块（PCB）的结构与初始化。

## 练习1：分配并初始化一个进程控制块

`alloc_proc` 函数（位于 `kern/process/proc.c`）负责分配并返回一个新的 `struct proc_struct` 结构，用于存储新建立的内核线程的管理信息。

### 1.1 设计与实现

`alloc_proc` 的主要职责是分配内存并对 `proc_struct` 中的成员变量进行清零或赋予默认值。

```c++
// kern/process/proc.c
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 2311983
        proc->state = PROC_UNINIT;      // 设置进程为未初始化状态
        proc->pid = -1;                 // 未分配PID，初始化为-1
        proc->runs = 0;                 // 运行时间初始化为0
        proc->kstack = 0;               // 内核栈地址初始化为0
        proc->need_resched = 0;         // 不需要调度
        proc->parent = NULL;            // 父进程为空
        proc->mm = NULL;                // 内存管理结构为空（内核线程共享内核内存）
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
        proc->tf = NULL;                // 中断帧指针初始化为NULL
        proc->pgdir = boot_pgdir_pa;    // 页目录设为内核页目录的物理地址（关键：内核线程共用内核页表）
        proc->flags = 0;                // 标志位初始化
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 进程名清零
    }
    return proc;
}
```

### 1.2 问题回答

**请说明 `proc_struct` 中 `struct context context` 和 `struct trapframe \*tf` 成员变量含义和在本实验中的作用是什么？**

1. **struct context context**
   - **含义**：`context` 保存了进程在进行上下文切换时被暂停下来的那一刻的处理器状态。它主要包含被调用者保存的寄存器（如 `s0`-`s11`, `ra`, `sp`）。
   - **作用**：当 `switch_to` 函数被调用时，当前进程的寄存器值会被保存在其 `context` 中；而 CPU 会加载下一个进程 `context` 中的值，从而跳转到新进程上次暂停的位置继续执行（对于新创建的线程，通过设置 `context.ra = forkret` 和 `context.sp = tf`，使其开始执行 `forkret`）。
2. **struct trapframe \*tf**
   - **含义**：`tf` 是指向中断帧（Trap Frame）的指针。中断帧记录了进程在发生中断、异常或系统调用（用户态切换到内核态）瞬间的完整处理器状态（包括通用寄存器、PC/EPC、状态寄存器等）。
   - **作用**：
     - **构造新线程的入口环境**：在创建新线程（`copy_thread`）时，我们手动构造了一个 `tf` 并放在内核栈顶。这个 `tf` 设置了 `epc` 指向 `kernel_thread_entry`，`status` 寄存器开启中断等。
     - **执行流切换**：当线程被调度运行后，它首先执行 `forkret`，该函数通过加载 `tf` 中的内容到 CPU 寄存器（`forkrets` -> `__trapret`），模拟从中断返回的过程，从而“返回”到我们预设的 `kernel_thread_entry` 函数开始真正执行代码。

## 练习2：为新创建的内核线程分配资源

`do_fork` 函数是创建新进程/线程的核心函数。它完成资源的分配、内容的复制以及进程链表的维护。

### 2.1 设计与实现

`do_fork` 的执行流程如下：

1. 调用 `alloc_proc` 分配 PCB。
2. 调用 `setup_kstack` 分配内核栈。
3. 调用 `copy_mm` 复制/共享内存管理信息（内核线程共享，`clone_flags` 含 `CLONE_VM`）。
4. 调用 `copy_thread` 设置中断帧和上下文。
5. 分配 PID 并将进程加入全局链表（需关中断保护）。
6. 唤醒进程。

```c
// kern/process/proc.c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2 2311983
    // 1. 分配并初始化进程控制块
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    // 设置父进程
    proc->parent = current;
    // 2. 分配内核栈
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    // 3. 复制/共享内存管理信息
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    // 4. 设置中断帧和上下文
    copy_thread(proc, stack, tf);
    // 5. 将新进程加入进程列表（需要原子操作，故关中断）
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid(); // 获取唯一PID
        hash_proc(proc);       // 加入哈希表
        list_add(&proc_list, &(proc->list_link)); // 加入进程链表
        nr_process++;
    }
    local_intr_restore(intr_flag);
    // 6. 唤醒新进程，将其状态设置为 RUNNABLE
    wakeup_proc(proc);
    // 7. 返回新进程的 PID
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

### 2.2 问题回答

**请说明 ucore 是否做到给每个新 fork 的线程一个唯一的 id？请说明你的分析和理由。**

**是，ucore 能够保证分配唯一的 PID。**

**分析**： 这主要依赖于 `kern/process/proc.c` 中的 `get_pid` 函数的实现逻辑：

1. **递增分配与回绕**：使用静态变量 `last_pid` 记录上一次分配的 PID。每次分配时 `last_pid` 自增。如果超过 `MAX_PID`，则重置为 1。
2. **冲突检测**：在确定一个候选 `last_pid` 后，函数会遍历整个 `proc_list` 链表。
3. **保证唯一性**：如果发现链表中已经有一个进程的 PID 等于候选的 `last_pid`，说明冲突，于是 `last_pid` 继续自增，并重新开始遍历检查。只有当遍历完所有现有进程且未发现冲突时，该 PID 才会被返回。这确保了只要总进程数未超过 `MAX_PID`，就一定能找到一个唯一的 PID。

## 练习3：编写 proc_run 函数

`proc_run` 函数用于将当前 CPU 的执行权切换到指定的进程。

### 3.1 设计与实现

根据题目要求和提供的正确代码逻辑，实现步骤包括检查进程、关中断、切换 current 指针、切换页表、切换上下文、恢复中断。

```c
// kern/process/proc.c

void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        // LAB4:EXERCISE3 2311983
        bool intr_flag;
        struct proc_struct *prev = current;
        // 1. 禁用中断，保护进程切换过程
        local_intr_save(intr_flag);
        {
            // 2. 切换当前进程指针
            current = proc;
            // 3. 切换页表，加载新进程的页目录表物理地址到 satp 寄存器
            // 内核线程虽然共用内核页表，但为了统一性，这里依然进行重新加载
            lsatp(proc->pgdir); 
            // 4. 实现上下文切换
            // 保存 prev 的上下文，恢复 proc 的上下文
            // 这一步完成后，代码执行流将跳转到 proc 进程上次暂停的地方（或 forkret）
            switch_to(&(prev->context), &(proc->context));
        }
        // 5. 恢复中断状态
        local_intr_restore(intr_flag);
    }
}
```

### 3.2 问题回答

**在本实验的执行过程中，创建且运行了几个内核线程？**

**两个。**

1. **idleproc (PID 0)**：
   - 这是第 0 个内核线程，也称为空闲进程。
   - 它是在 `proc_init` 函数中通过 `alloc_proc` 手动创建并初始化的，没有通过 `fork`。
   - 它的作用是当没有其他就绪进程时，CPU 执行 `cpu_idle` 函数（无限循环），以等待调度。
2. **initproc (PID 1)**：
   - 这是第 1 个内核线程。
   - 它是在 `proc_init` 中通过调用 `kernel_thread` 函数（底层调用 `do_fork`）创建的。
   - 它的入口函数是 `init_main`，在本实验中，它的任务就是输出一段 "Hello World" 字符串，表明内核线程机制工作正常。

运行 `make qemu` 后，输出：

<p align="center">
  <img src="success1.png" width="60%">
  <br>
</p>

这表明 `idleproc` 成功调度了 `initproc` 运行。

## 扩展练习 Challenge

### 说明语句 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);` 是如何实现开关中断的

具体实现位于 `kern/sync/sync.h`。

1. **保存状态 (`local_intr_save`)**：
   - 宏展开调用 `__intr_save()`。
   - 该函数首先通过 `read_csr(sstatus)` 读取当前的 `sstatus` 寄存器。
   - 检查 `SSTATUS_SIE`（Supervisor Interrupt Enable）位。
   - **如果原来是开中断的**：调用 `intr_disable()`（执行 `csrc sstatus, SSTATUS_SIE`）关闭中断，并返回 `1`。
   - **如果原来是关中断的**：不改变状态，直接返回 `0`。
   - 这个返回值（1 或 0）被保存在局部变量 `intr_flag` 中。
2. **恢复状态 (`local_intr_restore`)**：
   - 宏展开调用 `__intr_restore(intr_flag)`。
   - **如果 `intr_flag` 为 1**：说明进入临界区前是开中断的，因此调用 `intr_enable()`（执行 `csrs sstatus, SSTATUS_SIE`）重新开启中断。
   - **如果 `intr_flag` 为 0**：说明进入临界区前已经是关中断的（可能是被外层函数关闭的），因此**保持关中断状态**，不执行开启操作。

这种方式保证了在退出临界区时，中断状态能够恢复到进入临界区之前的状态，而不是强制开启，从而支持了函数的嵌套调用安全性。

### 深入理解不同分页模式的工作原理（思考题）

#### 1. get_pte() 中两段相似代码的解释

在 `get_pte()` 函数中，处理 PDX1（一级页目录索引）和 PDX0（二级页目录索引）的代码逻辑相似。

- **原因**：RISC-V 的 Sv39 分页模式采用三级页表结构（Page Directory Pointer -> Page Directory -> Page Table）。
- **递归/迭代结构**：多级页表的每一级查找逻辑在本质上是相同的：
  1. 根据虚拟地址的某一部分（如 PDX1 或 PDX0）找到当前页表页中的页表项（PTE）。
  2. 检查该 PTE 的有效位（PTE_V）。
  3. 如果无效（说明下一级页表不存在），则分配一个新的物理页作为下一级页表，清零，并更新当前 PTE 指向这个新页。
  4. 如果有效，则获取下一级页表的基地址，继续下一级的查找。
- 代码中第一段处理 PDX1 索引以获取第二级页表的基址，第二段处理 PDX0 索引以获取第三级（叶子）页表的基址，两者的操作逻辑完全一致，只是操作的层级不同。

#### 2. 关于 get_pte() 合并查找与分配的看法

将查找和分配功能合并在 `get_pte` 中，并使用 `create` 参数控制，有好处有不足。

- **好的方面**：
  - **代码复用**：在建立映射（如 `page_insert`）时，如果中间页表不存在，必须立即创建。合并写法避免了调用者先查询失败再调用分配函数的重复逻辑。
  - **原子性语义**：对于“获取页表项以便写入”的操作，逻辑上就是希望“保证该页表项存在”，合并写法直接满足了这一需求。
- **改进空间**：
  - **单一职责原则**：查找（Query）和修改/分配（Command）是两种不同的意图。如果仅想查询某地址是否映射，调用 `get_pte` 时必须小心传递 `create=false`。
  - **拆分**：可以拆分为 `lookup_pte()`（只查不建，返回 NULL）和 `walk_and_create_pte()`（查找并在必要时创建）。这样在只需查询（如缺页处理的某些检查路径）时代码语义更清晰，而在建立映射时使用后者。
  