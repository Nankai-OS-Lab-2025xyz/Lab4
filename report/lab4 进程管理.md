# lab4: 进程管理

## 实验目的

- 了解虚拟内存管理的基本结构，掌握虚拟内存的组织与管理方式
- 了解内核线程创建/执行的管理过程
- 了解内核线程的切换和基本调度过程

## 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

  ------

  alloc_proc函数是一个实现进程控制块初始化的函数，他负责初始化一个进程控制块，首先我们需要找到代码的位置，然后根据这个结构的中的结构进行初始化。

```c++
// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 2312282 CODE
        proc->state = PROC_UNINIT;//进程状态设置为未启动的状态
        proc->pid = -1;//进程ID设置为-1，表示未分配
        proc->runs = 0;//运行次数初始化为0
        proc->kstack = 0;//内核栈指针初始化为0
        proc->need_resched = 0;//不需要重新调度
        proc->parent = NULL;//父进程指针初始化为NULL
        proc->mm = NULL;//内存管理结构初始化为NULL
        memset(&(proc->context), 0, sizeof(struct context));//上下文结构体清零
        proc->tf = NULL;//陷阱帧指针初始化为NULL
        proc->pgdir = boot_pgdir_pa;//页目录基址设置为引导页目录物理地址
        proc->flags = 0;//进程标志初始化为0
        memset(proc->name, 0, sizeof(proc->name));//进程名称清零
        /*
         * below fields in proc_struct need to be initialized
         *       enum proc_state state;                      // Process state
         *       int pid;                                    // Process ID
         *       int runs;                                   // the running times of Proces
         *       uintptr_t kstack;                           // Process kernel stack
         *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
         *       struct proc_struct *parent;                 // the parent process
         *       struct mm_struct *mm;                       // Process's memory management field
         *       struct context context;                     // Switch here to run process
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        
    }
    return proc;
}
```

如代码所示，每一个结构体中各个成员变量的初始化设置如代码所示，其中注释中说明了每一个成员变量的初始化含义。

**struct context context**

**含义**：

- 进程的上下文切换信息，保存了进程被切换出去时的关键寄存器状态
- 包括：一些关键的寄存器，这些寄存器的值用于在进程切换中还原之前进程的运行状态

**作用**：

- **进程切换**：当发生进程切换时，保存当前进程的执行上下文，以便下次恢复执行时能继续从正确的位置运行

通过`memset(&(proc->context), 0, sizeof(struct context))`进行初始化。

**struct trapframe *tf**

**含义**：

- 保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中
- 包含所有通用寄存器、段寄存器、错误码、中断号等信息

**作用**：

- **中断处理**：在中断/异常发生时保存处理器的完整状态
- **系统调用**：用户态到内核态切换时保存用户态上下文
- **进程恢复**：从内核态返回用户态时恢复进程执行环境
- **特权级切换**：协助完成用户态和内核态之间的切换

在初始化代码中设置为`NULL`，因为在进程创建时还没有发生中断。

## 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

------

接下来我们要进城创建内核进程，如何创建，在课堂上讲过，我们通过fork来将正在运行的进程信息fork到新的进程中来，以此实现了新进程的创建。

```c++
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2  2312282 YOUR CODE
    // 1. 调用alloc_proc函数，获取一块用户信息块
    proc = alloc_proc();
    if (proc == NULL)
        goto fork_out;

    // 2.使用setup_kstack函数 直接为进程分配一个内核栈
    if (setup_kstack(proc) < 0)
        goto bad_fork_cleanup_proc;

    // 3.利用copy_mm（）函数 复制原来进程的内存管理信息到新进程中来
    if (copy_mm(clone_flags, proc) < 0)
        goto bad_fork_cleanup_kstack;

    // 4. 利用copy_thread（）函数复制原来进程上下文到新进程中来
    copy_thread(proc, stack, tf);

    // 5. 完善新进程的信息
    proc->parent = current;
    proc->pid = get_pid();//注意，该函数时设置进程编号的函数，这个函数规定了每个线程只能有一个唯一的id。
    proc->state = PROC_UNINIT; // 在wakeup_proc中设置为RUNNABLE
    proc->runs = 0;

    // 6. 添加到进程列表中（libs/list.h 提供 list_add_before/list_add_after）
    /* 使用 list_add_before 在队尾插入 */
    list_add_before(&proc_list, &proc->list_link);
    hash_proc(proc);

    nr_process++;//目前进程数加1

    // 7. 唤醒新进程
    wakeup_proc(proc);

    // 8. 返回新进程号
    ret = proc->pid;

    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

如代码所示，具体实现过程如注释所示。

------

请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

可以做到，这个具体需要看get_pid()函数的内容。

**1. 基本分配策略**

```c++
static int next_safe = MAX_PID, last_pid = MAX_PID;
if (++last_pid >= MAX_PID)
{
    last_pid = 1;  // 超过最大值时回绕到1
    goto inside;
}
```

- 使用递增分配策略，从1开始分配
- 当达到`MAX_PID`时回绕到1重新开始

**2. 唯一性保证机制**

```c++
while ((le = list_next(le)) != list)
{
    proc = le2proc(le, list_link);
    if (proc->pid == last_pid)  // 发现PID冲突
    {
        if (++last_pid >= next_safe)
        {
            // 重新扫描所有进程
            goto repeat;
        }
    }
    else if (proc->pid > last_pid && next_safe > proc->pid)
    {
        next_safe = proc->pid;  // 更新安全边界
    }
}
```

**关键保证机制**：

- **遍历检查**：每次分配前遍历整个进程链表检查PID是否已被使用
- **冲突处理**：如果发现冲突，递增PID并重新检查
- **安全边界**：通过`next_safe`记录下一个已被占用的PID，优化搜索范围

**3. 完备性证明**

```c++
static_assert(MAX_PID > MAX_PROCESS);
```

这是一个静态断言，这个静态断言确保了：

- **PID数量 > 最大进程数**：只要有空闲PID就一定能分配成功
- **不会死锁**：最多检查MAX_PID次就能找到可用PID

但是，如果我们的进程数量超过了最大的编号数量，会导致无限循环，永远找不到空闲PID。（其中，出现一个问题就是，缺少了边界检查，也就是说，当我们的遍历完了所有的pid之后，发现没有可以用到的pid，我们就需要退出，不再进行创建。）

## 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

------

proc_run函数时将我们指定的进程换到CPU上面来执行，具体的切换主要注意的是，切换过程中我们需要禁用中断，并且将相关的页表和上下文进行切换，切换完成之后，再次允许中断。

```c++
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        // LAB4:EXERCISE3  2312282 YOUR CODE
        /*
         * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
         * MACROs or Functions:
         *   local_intr_save():        Disable interrupts
         *   local_intr_restore():     Enable Interrupts
         *   lsatp():                   Modify the value of satp register
         *   switch_to():              Context switching between two processes
         */
        // LAB4:EXERCISE3
        // 1. 禁用中断,使用我们的local_intr_save（）函数，注意的是我们需要一个指针指向原来的进程，也即是现在的进程，用来保证页表和上下文的切换
        bool intr_flag;
        struct proc_struct *prev = current;
        local_intr_save(intr_flag);

        // 2. 将当前进程指针切换到新进程
        current = proc;

        // 3.切换页表 (satp),修改SATP寄存器
        lsatp((unsigned int)proc->pgdir);

        // 4. 实现上下文切换
        switch_to(&(prev->context), &(proc->context));

        // 5. 允许中断
        local_intr_restore(intr_flag);
    }
}
```

在本实验的执行过程中，创建且运行了几个内核线程？

创建并且运行了2个内核进程。

第一个内核进程是idleproc，表示空闲进程。在操作系统中，空闲进程是一个特殊的进程，它的主要目的是在系统没有其他任务需要执行时，占用 CPU 时间，同时便于进程调度的统一化。通过执行cpu_idle函数，也就是一直循环，找到需要执行的进程。

第二个内核进程是initproc，他是fork的idleproc进程，其内容是打印出来（Hello world!!）

实验结果：

![image-20251105112004813](C:\Users\dell\AppData\Roaming\Typora\typora-user-images\image-20251105112004813.png)

发现我们成功完成了进程初始化，新进程的创建（fork），以及进程的切换的工作。