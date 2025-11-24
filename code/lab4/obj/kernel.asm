
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	62f030ef          	jal	ra,ffffffffc0203e90 <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e7258593          	addi	a1,a1,-398 # ffffffffc0203ee0 <etext+0x2>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e8a50513          	addi	a0,a0,-374 # ffffffffc0203f00 <etext+0x22>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0dc020ef          	jal	ra,ffffffffc0202162 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	645020ef          	jal	ra,ffffffffc0202ed6 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5ba030ef          	jal	ra,ffffffffc0203650 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7fc030ef          	jal	ra,ffffffffc020389e <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	e4c50513          	addi	a0,a0,-436 # ffffffffc0203f08 <etext+0x2a>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	0e5030ef          	jal	ra,ffffffffc0203a6c <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0af030ef          	jal	ra,ffffffffc0203a6c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	d3250513          	addi	a0,a0,-718 # ffffffffc0203f10 <etext+0x32>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	d3c50513          	addi	a0,a0,-708 # ffffffffc0203f30 <etext+0x52>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	cde58593          	addi	a1,a1,-802 # ffffffffc0203ede <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	d4850513          	addi	a0,a0,-696 # ffffffffc0203f50 <etext+0x72>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d5450513          	addi	a0,a0,-684 # ffffffffc0203f70 <etext+0x92>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d6050513          	addi	a0,a0,-672 # ffffffffc0203f90 <etext+0xb2>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d5250513          	addi	a0,a0,-686 # ffffffffc0203fb0 <etext+0xd2>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d7460613          	addi	a2,a2,-652 # ffffffffc0203fe0 <etext+0x102>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d8050513          	addi	a0,a0,-640 # ffffffffc0203ff8 <etext+0x11a>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d8860613          	addi	a2,a2,-632 # ffffffffc0204010 <etext+0x132>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	da058593          	addi	a1,a1,-608 # ffffffffc0204030 <etext+0x152>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	da050513          	addi	a0,a0,-608 # ffffffffc0204038 <etext+0x15a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	da260613          	addi	a2,a2,-606 # ffffffffc0204048 <etext+0x16a>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	dc258593          	addi	a1,a1,-574 # ffffffffc0204070 <etext+0x192>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d8250513          	addi	a0,a0,-638 # ffffffffc0204038 <etext+0x15a>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	dbe60613          	addi	a2,a2,-578 # ffffffffc0204080 <etext+0x1a2>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	dd658593          	addi	a1,a1,-554 # ffffffffc02040a0 <etext+0x1c2>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d6650513          	addi	a0,a0,-666 # ffffffffc0204038 <etext+0x15a>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	da450513          	addi	a0,a0,-604 # ffffffffc02040b0 <etext+0x1d2>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	daa50513          	addi	a0,a0,-598 # ffffffffc02040d8 <etext+0x1fa>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	df8c0c13          	addi	s8,s8,-520 # ffffffffc0204148 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	da890913          	addi	s2,s2,-600 # ffffffffc0204100 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	da848493          	addi	s1,s1,-600 # ffffffffc0204108 <etext+0x22a>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	da6b0b13          	addi	s6,s6,-602 # ffffffffc0204110 <etext+0x232>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	cbea0a13          	addi	s4,s4,-834 # ffffffffc0204030 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	db4d0d13          	addi	s10,s10,-588 # ffffffffc0204148 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	295030ef          	jal	ra,ffffffffc0203e36 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	281030ef          	jal	ra,ffffffffc0203e36 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	287030ef          	jal	ra,ffffffffc0203e7a <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	249030ef          	jal	ra,ffffffffc0203e7a <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	ce450513          	addi	a0,a0,-796 # ffffffffc0204130 <etext+0x252>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	d0850513          	addi	a0,a0,-760 # ffffffffc0204190 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	da250513          	addi	a0,a0,-606 # ffffffffc0205240 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	cd450513          	addi	a0,a0,-812 # ffffffffc02041b0 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c5450513          	addi	a0,a0,-940 # ffffffffc02041d0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	c3650513          	addi	a0,a0,-970 # ffffffffc02041e0 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	c3050513          	addi	a0,a0,-976 # ffffffffc02041f0 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	c3850513          	addi	a0,a0,-968 # ffffffffc0204208 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	bce90913          	addi	s2,s2,-1074 # ffffffffc0204258 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	bb848493          	addi	s1,s1,-1096 # ffffffffc0204250 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	be450513          	addi	a0,a0,-1052 # ffffffffc02042d0 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	c1050513          	addi	a0,a0,-1008 # ffffffffc0204308 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204228 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	6a8030ef          	jal	ra,ffffffffc0203dee <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	700030ef          	jal	ra,ffffffffc0203e54 <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	64c030ef          	jal	ra,ffffffffc0203e36 <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204260 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	9b450513          	addi	a0,a0,-1612 # ffffffffc0204280 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0204298 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	9c850513          	addi	a0,a0,-1592 # ffffffffc02042b8 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0204308 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	3ec78793          	addi	a5,a5,1004 # ffffffffc0200d28 <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0204320 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0204338 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	9d850513          	addi	a0,a0,-1576 # ffffffffc0204350 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	9e250513          	addi	a0,a0,-1566 # ffffffffc0204368 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0204380 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9f650513          	addi	a0,a0,-1546 # ffffffffc0204398 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02043b0 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02043c8 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	a1450513          	addi	a0,a0,-1516 # ffffffffc02043e0 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02043f8 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204410 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204428 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0204440 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204458 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204470 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0204488 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a6450513          	addi	a0,a0,-1436 # ffffffffc02044a0 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02044b8 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a7850513          	addi	a0,a0,-1416 # ffffffffc02044d0 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a8250513          	addi	a0,a0,-1406 # ffffffffc02044e8 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204500 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204518 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204530 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204548 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	ab450513          	addi	a0,a0,-1356 # ffffffffc0204560 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	abe50513          	addi	a0,a0,-1346 # ffffffffc0204578 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	ac850513          	addi	a0,a0,-1336 # ffffffffc0204590 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	ad250513          	addi	a0,a0,-1326 # ffffffffc02045a8 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	adc50513          	addi	a0,a0,-1316 # ffffffffc02045c0 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	ae650513          	addi	a0,a0,-1306 # ffffffffc02045d8 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	af050513          	addi	a0,a0,-1296 # ffffffffc02045f0 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	af650513          	addi	a0,a0,-1290 # ffffffffc0204608 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	af850513          	addi	a0,a0,-1288 # ffffffffc0204620 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	af850513          	addi	a0,a0,-1288 # ffffffffc0204638 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	b0050513          	addi	a0,a0,-1280 # ffffffffc0204650 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204668 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204680 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	06f76f63          	bltu	a4,a5,ffffffffc0200c0a <interrupt_handler+0x88>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	bb870713          	addi	a4,a4,-1096 # ffffffffc0204748 <commands+0x600>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b5650513          	addi	a0,a0,-1194 # ffffffffc02046f8 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	b2a50513          	addi	a0,a0,-1238 # ffffffffc02046d8 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204698 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	af250513          	addi	a0,a0,-1294 # ffffffffc02046b8 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e406                	sd	ra,8(sp)
ffffffffc0200bd6:	e022                	sd	s0,0(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();//又调用 sbi_set_timer 预约了下一次 10ms 后的中断。
ffffffffc0200bd8:	917ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
            ticks+=1;
ffffffffc0200bdc:	0000d797          	auipc	a5,0xd
ffffffffc0200be0:	89478793          	addi	a5,a5,-1900 # ffffffffc020d470 <ticks>
ffffffffc0200be4:	6398                	ld	a4,0(a5)
ffffffffc0200be6:	0705                	addi	a4,a4,1
ffffffffc0200be8:	e398                	sd	a4,0(a5)
            if(ticks%TICK_NUM==0){
ffffffffc0200bea:	639c                	ld	a5,0(a5)
ffffffffc0200bec:	06400713          	li	a4,100
ffffffffc0200bf0:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bf4:	cf81                	beqz	a5,ffffffffc0200c0c <interrupt_handler+0x8a>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
ffffffffc0200bf8:	6402                	ld	s0,0(sp)
ffffffffc0200bfa:	0141                	addi	sp,sp,16
ffffffffc0200bfc:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bfe:	00004517          	auipc	a0,0x4
ffffffffc0200c02:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0204728 <commands+0x5e0>
ffffffffc0200c06:	d8eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c0a:	bf19                	j	ffffffffc0200b20 <print_trapframe>
                num+=1;
ffffffffc0200c0c:	0000d797          	auipc	a5,0xd
ffffffffc0200c10:	8847a783          	lw	a5,-1916(a5) # ffffffffc020d490 <num>
ffffffffc0200c14:	2785                	addiw	a5,a5,1
ffffffffc0200c16:	0000d417          	auipc	s0,0xd
ffffffffc0200c1a:	87a40413          	addi	s0,s0,-1926 # ffffffffc020d490 <num>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c1e:	06400593          	li	a1,100
ffffffffc0200c22:	00004517          	auipc	a0,0x4
ffffffffc0200c26:	af650513          	addi	a0,a0,-1290 # ffffffffc0204718 <commands+0x5d0>
                num+=1;
ffffffffc0200c2a:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c2c:	d68ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
                if(num==10){
ffffffffc0200c30:	401c                	lw	a5,0(s0)
ffffffffc0200c32:	4729                	li	a4,10
ffffffffc0200c34:	2781                	sext.w	a5,a5
ffffffffc0200c36:	fce790e3          	bne	a5,a4,ffffffffc0200bf6 <interrupt_handler+0x74>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c3a:	4501                	li	a0,0
ffffffffc0200c3c:	4581                	li	a1,0
ffffffffc0200c3e:	4601                	li	a2,0
ffffffffc0200c40:	48a1                	li	a7,8
ffffffffc0200c42:	00000073          	ecall
}
ffffffffc0200c46:	bf45                	j	ffffffffc0200bf6 <interrupt_handler+0x74>

ffffffffc0200c48 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c48:	11853783          	ld	a5,280(a0)
ffffffffc0200c4c:	473d                	li	a4,15
ffffffffc0200c4e:	0cf76563          	bltu	a4,a5,ffffffffc0200d18 <exception_handler+0xd0>
ffffffffc0200c52:	00004717          	auipc	a4,0x4
ffffffffc0200c56:	cbe70713          	addi	a4,a4,-834 # ffffffffc0204910 <commands+0x7c8>
ffffffffc0200c5a:	078a                	slli	a5,a5,0x2
ffffffffc0200c5c:	97ba                	add	a5,a5,a4
ffffffffc0200c5e:	439c                	lw	a5,0(a5)
ffffffffc0200c60:	97ba                	add	a5,a5,a4
ffffffffc0200c62:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c64:	00004517          	auipc	a0,0x4
ffffffffc0200c68:	c9450513          	addi	a0,a0,-876 # ffffffffc02048f8 <commands+0x7b0>
ffffffffc0200c6c:	d28ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c70:	00004517          	auipc	a0,0x4
ffffffffc0200c74:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204778 <commands+0x630>
ffffffffc0200c78:	d1cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c7c:	00004517          	auipc	a0,0x4
ffffffffc0200c80:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204798 <commands+0x650>
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c88:	00004517          	auipc	a0,0x4
ffffffffc0200c8c:	b3050513          	addi	a0,a0,-1232 # ffffffffc02047b8 <commands+0x670>
ffffffffc0200c90:	d04ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c94:	00004517          	auipc	a0,0x4
ffffffffc0200c98:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02047d0 <commands+0x688>
ffffffffc0200c9c:	cf8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200ca0:	00004517          	auipc	a0,0x4
ffffffffc0200ca4:	b4050513          	addi	a0,a0,-1216 # ffffffffc02047e0 <commands+0x698>
ffffffffc0200ca8:	cecff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200cac:	00004517          	auipc	a0,0x4
ffffffffc0200cb0:	b5450513          	addi	a0,a0,-1196 # ffffffffc0204800 <commands+0x6b8>
ffffffffc0200cb4:	ce0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cb8:	00004517          	auipc	a0,0x4
ffffffffc0200cbc:	b6050513          	addi	a0,a0,-1184 # ffffffffc0204818 <commands+0x6d0>
ffffffffc0200cc0:	cd4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cc4:	00004517          	auipc	a0,0x4
ffffffffc0200cc8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204830 <commands+0x6e8>
ffffffffc0200ccc:	cc8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cd0:	00004517          	auipc	a0,0x4
ffffffffc0200cd4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0204848 <commands+0x700>
ffffffffc0200cd8:	cbcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cdc:	00004517          	auipc	a0,0x4
ffffffffc0200ce0:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204868 <commands+0x720>
ffffffffc0200ce4:	cb0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200ce8:	00004517          	auipc	a0,0x4
ffffffffc0200cec:	ba050513          	addi	a0,a0,-1120 # ffffffffc0204888 <commands+0x740>
ffffffffc0200cf0:	ca4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cf4:	00004517          	auipc	a0,0x4
ffffffffc0200cf8:	bb450513          	addi	a0,a0,-1100 # ffffffffc02048a8 <commands+0x760>
ffffffffc0200cfc:	c98ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200d00:	00004517          	auipc	a0,0x4
ffffffffc0200d04:	bc850513          	addi	a0,a0,-1080 # ffffffffc02048c8 <commands+0x780>
ffffffffc0200d08:	c8cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d0c:	00004517          	auipc	a0,0x4
ffffffffc0200d10:	bd450513          	addi	a0,a0,-1068 # ffffffffc02048e0 <commands+0x798>
ffffffffc0200d14:	c80ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d18:	b521                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d1a <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d1a:	11853783          	ld	a5,280(a0)
ffffffffc0200d1e:	0007c363          	bltz	a5,ffffffffc0200d24 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d22:	b71d                	j	ffffffffc0200c48 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d24:	bdb9                	j	ffffffffc0200b82 <interrupt_handler>
	...

ffffffffc0200d28 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d28:	14011073          	csrw	sscratch,sp
ffffffffc0200d2c:	712d                	addi	sp,sp,-288
ffffffffc0200d2e:	e406                	sd	ra,8(sp)
ffffffffc0200d30:	ec0e                	sd	gp,24(sp)
ffffffffc0200d32:	f012                	sd	tp,32(sp)
ffffffffc0200d34:	f416                	sd	t0,40(sp)
ffffffffc0200d36:	f81a                	sd	t1,48(sp)
ffffffffc0200d38:	fc1e                	sd	t2,56(sp)
ffffffffc0200d3a:	e0a2                	sd	s0,64(sp)
ffffffffc0200d3c:	e4a6                	sd	s1,72(sp)
ffffffffc0200d3e:	e8aa                	sd	a0,80(sp)
ffffffffc0200d40:	ecae                	sd	a1,88(sp)
ffffffffc0200d42:	f0b2                	sd	a2,96(sp)
ffffffffc0200d44:	f4b6                	sd	a3,104(sp)
ffffffffc0200d46:	f8ba                	sd	a4,112(sp)
ffffffffc0200d48:	fcbe                	sd	a5,120(sp)
ffffffffc0200d4a:	e142                	sd	a6,128(sp)
ffffffffc0200d4c:	e546                	sd	a7,136(sp)
ffffffffc0200d4e:	e94a                	sd	s2,144(sp)
ffffffffc0200d50:	ed4e                	sd	s3,152(sp)
ffffffffc0200d52:	f152                	sd	s4,160(sp)
ffffffffc0200d54:	f556                	sd	s5,168(sp)
ffffffffc0200d56:	f95a                	sd	s6,176(sp)
ffffffffc0200d58:	fd5e                	sd	s7,184(sp)
ffffffffc0200d5a:	e1e2                	sd	s8,192(sp)
ffffffffc0200d5c:	e5e6                	sd	s9,200(sp)
ffffffffc0200d5e:	e9ea                	sd	s10,208(sp)
ffffffffc0200d60:	edee                	sd	s11,216(sp)
ffffffffc0200d62:	f1f2                	sd	t3,224(sp)
ffffffffc0200d64:	f5f6                	sd	t4,232(sp)
ffffffffc0200d66:	f9fa                	sd	t5,240(sp)
ffffffffc0200d68:	fdfe                	sd	t6,248(sp)
ffffffffc0200d6a:	14002473          	csrr	s0,sscratch
ffffffffc0200d6e:	100024f3          	csrr	s1,sstatus
ffffffffc0200d72:	14102973          	csrr	s2,sepc
ffffffffc0200d76:	143029f3          	csrr	s3,stval
ffffffffc0200d7a:	14202a73          	csrr	s4,scause
ffffffffc0200d7e:	e822                	sd	s0,16(sp)
ffffffffc0200d80:	e226                	sd	s1,256(sp)
ffffffffc0200d82:	e64a                	sd	s2,264(sp)
ffffffffc0200d84:	ea4e                	sd	s3,272(sp)
ffffffffc0200d86:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d88:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d8a:	f91ff0ef          	jal	ra,ffffffffc0200d1a <trap>

ffffffffc0200d8e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d8e:	6492                	ld	s1,256(sp)
ffffffffc0200d90:	6932                	ld	s2,264(sp)
ffffffffc0200d92:	10049073          	csrw	sstatus,s1
ffffffffc0200d96:	14191073          	csrw	sepc,s2
ffffffffc0200d9a:	60a2                	ld	ra,8(sp)
ffffffffc0200d9c:	61e2                	ld	gp,24(sp)
ffffffffc0200d9e:	7202                	ld	tp,32(sp)
ffffffffc0200da0:	72a2                	ld	t0,40(sp)
ffffffffc0200da2:	7342                	ld	t1,48(sp)
ffffffffc0200da4:	73e2                	ld	t2,56(sp)
ffffffffc0200da6:	6406                	ld	s0,64(sp)
ffffffffc0200da8:	64a6                	ld	s1,72(sp)
ffffffffc0200daa:	6546                	ld	a0,80(sp)
ffffffffc0200dac:	65e6                	ld	a1,88(sp)
ffffffffc0200dae:	7606                	ld	a2,96(sp)
ffffffffc0200db0:	76a6                	ld	a3,104(sp)
ffffffffc0200db2:	7746                	ld	a4,112(sp)
ffffffffc0200db4:	77e6                	ld	a5,120(sp)
ffffffffc0200db6:	680a                	ld	a6,128(sp)
ffffffffc0200db8:	68aa                	ld	a7,136(sp)
ffffffffc0200dba:	694a                	ld	s2,144(sp)
ffffffffc0200dbc:	69ea                	ld	s3,152(sp)
ffffffffc0200dbe:	7a0a                	ld	s4,160(sp)
ffffffffc0200dc0:	7aaa                	ld	s5,168(sp)
ffffffffc0200dc2:	7b4a                	ld	s6,176(sp)
ffffffffc0200dc4:	7bea                	ld	s7,184(sp)
ffffffffc0200dc6:	6c0e                	ld	s8,192(sp)
ffffffffc0200dc8:	6cae                	ld	s9,200(sp)
ffffffffc0200dca:	6d4e                	ld	s10,208(sp)
ffffffffc0200dcc:	6dee                	ld	s11,216(sp)
ffffffffc0200dce:	7e0e                	ld	t3,224(sp)
ffffffffc0200dd0:	7eae                	ld	t4,232(sp)
ffffffffc0200dd2:	7f4e                	ld	t5,240(sp)
ffffffffc0200dd4:	7fee                	ld	t6,248(sp)
ffffffffc0200dd6:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200dd8:	10200073          	sret

ffffffffc0200ddc <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ddc:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dde:	bf45                	j	ffffffffc0200d8e <__trapret>
	...

ffffffffc0200de2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200de2:	00008797          	auipc	a5,0x8
ffffffffc0200de6:	64e78793          	addi	a5,a5,1614 # ffffffffc0209430 <free_area>
ffffffffc0200dea:	e79c                	sd	a5,8(a5)
ffffffffc0200dec:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200dee:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200df2:	8082                	ret

ffffffffc0200df4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200df4:	00008517          	auipc	a0,0x8
ffffffffc0200df8:	64c56503          	lwu	a0,1612(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200dfc:	8082                	ret

ffffffffc0200dfe <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200dfe:	715d                	addi	sp,sp,-80
ffffffffc0200e00:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e02:	00008417          	auipc	s0,0x8
ffffffffc0200e06:	62e40413          	addi	s0,s0,1582 # ffffffffc0209430 <free_area>
ffffffffc0200e0a:	641c                	ld	a5,8(s0)
ffffffffc0200e0c:	e486                	sd	ra,72(sp)
ffffffffc0200e0e:	fc26                	sd	s1,56(sp)
ffffffffc0200e10:	f84a                	sd	s2,48(sp)
ffffffffc0200e12:	f44e                	sd	s3,40(sp)
ffffffffc0200e14:	f052                	sd	s4,32(sp)
ffffffffc0200e16:	ec56                	sd	s5,24(sp)
ffffffffc0200e18:	e85a                	sd	s6,16(sp)
ffffffffc0200e1a:	e45e                	sd	s7,8(sp)
ffffffffc0200e1c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e1e:	2a878d63          	beq	a5,s0,ffffffffc02010d8 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e22:	4481                	li	s1,0
ffffffffc0200e24:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e26:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e2a:	8b09                	andi	a4,a4,2
ffffffffc0200e2c:	2a070a63          	beqz	a4,ffffffffc02010e0 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e30:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e34:	679c                	ld	a5,8(a5)
ffffffffc0200e36:	2905                	addiw	s2,s2,1
ffffffffc0200e38:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3a:	fe8796e3          	bne	a5,s0,ffffffffc0200e26 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e3e:	89a6                	mv	s3,s1
ffffffffc0200e40:	6db000ef          	jal	ra,ffffffffc0201d1a <nr_free_pages>
ffffffffc0200e44:	6f351e63          	bne	a0,s3,ffffffffc0201540 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e48:	4505                	li	a0,1
ffffffffc0200e4a:	653000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200e4e:	8aaa                	mv	s5,a0
ffffffffc0200e50:	42050863          	beqz	a0,ffffffffc0201280 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	647000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200e5a:	89aa                	mv	s3,a0
ffffffffc0200e5c:	70050263          	beqz	a0,ffffffffc0201560 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e60:	4505                	li	a0,1
ffffffffc0200e62:	63b000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200e66:	8a2a                	mv	s4,a0
ffffffffc0200e68:	48050c63          	beqz	a0,ffffffffc0201300 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e6c:	293a8a63          	beq	s5,s3,ffffffffc0201100 <default_check+0x302>
ffffffffc0200e70:	28aa8863          	beq	s5,a0,ffffffffc0201100 <default_check+0x302>
ffffffffc0200e74:	28a98663          	beq	s3,a0,ffffffffc0201100 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e78:	000aa783          	lw	a5,0(s5)
ffffffffc0200e7c:	2a079263          	bnez	a5,ffffffffc0201120 <default_check+0x322>
ffffffffc0200e80:	0009a783          	lw	a5,0(s3)
ffffffffc0200e84:	28079e63          	bnez	a5,ffffffffc0201120 <default_check+0x322>
ffffffffc0200e88:	411c                	lw	a5,0(a0)
ffffffffc0200e8a:	28079b63          	bnez	a5,ffffffffc0201120 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e8e:	0000c797          	auipc	a5,0xc
ffffffffc0200e92:	62a7b783          	ld	a5,1578(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200e96:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e9a:	00005617          	auipc	a2,0x5
ffffffffc0200e9e:	b8e63603          	ld	a2,-1138(a2) # ffffffffc0205a28 <nbase>
ffffffffc0200ea2:	8719                	srai	a4,a4,0x6
ffffffffc0200ea4:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ea6:	0000c697          	auipc	a3,0xc
ffffffffc0200eaa:	60a6b683          	ld	a3,1546(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200eae:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eb0:	0732                	slli	a4,a4,0xc
ffffffffc0200eb2:	28d77763          	bgeu	a4,a3,ffffffffc0201140 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200eb6:	40f98733          	sub	a4,s3,a5
ffffffffc0200eba:	8719                	srai	a4,a4,0x6
ffffffffc0200ebc:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ebe:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ec0:	4cd77063          	bgeu	a4,a3,ffffffffc0201380 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200ec4:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ec8:	8799                	srai	a5,a5,0x6
ffffffffc0200eca:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ecc:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ece:	30d7f963          	bgeu	a5,a3,ffffffffc02011e0 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200ed2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ed4:	00043c03          	ld	s8,0(s0)
ffffffffc0200ed8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200edc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ee0:	e400                	sd	s0,8(s0)
ffffffffc0200ee2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200ee4:	00008797          	auipc	a5,0x8
ffffffffc0200ee8:	5407ae23          	sw	zero,1372(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200eec:	5b1000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200ef0:	2c051863          	bnez	a0,ffffffffc02011c0 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200ef4:	4585                	li	a1,1
ffffffffc0200ef6:	8556                	mv	a0,s5
ffffffffc0200ef8:	5e3000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_page(p1);
ffffffffc0200efc:	4585                	li	a1,1
ffffffffc0200efe:	854e                	mv	a0,s3
ffffffffc0200f00:	5db000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_page(p2);
ffffffffc0200f04:	4585                	li	a1,1
ffffffffc0200f06:	8552                	mv	a0,s4
ffffffffc0200f08:	5d3000ef          	jal	ra,ffffffffc0201cda <free_pages>
    assert(nr_free == 3);
ffffffffc0200f0c:	4818                	lw	a4,16(s0)
ffffffffc0200f0e:	478d                	li	a5,3
ffffffffc0200f10:	28f71863          	bne	a4,a5,ffffffffc02011a0 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f14:	4505                	li	a0,1
ffffffffc0200f16:	587000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f1a:	89aa                	mv	s3,a0
ffffffffc0200f1c:	26050263          	beqz	a0,ffffffffc0201180 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f20:	4505                	li	a0,1
ffffffffc0200f22:	57b000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f26:	8aaa                	mv	s5,a0
ffffffffc0200f28:	3a050c63          	beqz	a0,ffffffffc02012e0 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f2c:	4505                	li	a0,1
ffffffffc0200f2e:	56f000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f32:	8a2a                	mv	s4,a0
ffffffffc0200f34:	38050663          	beqz	a0,ffffffffc02012c0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f38:	4505                	li	a0,1
ffffffffc0200f3a:	563000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f3e:	36051163          	bnez	a0,ffffffffc02012a0 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f42:	4585                	li	a1,1
ffffffffc0200f44:	854e                	mv	a0,s3
ffffffffc0200f46:	595000ef          	jal	ra,ffffffffc0201cda <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f4a:	641c                	ld	a5,8(s0)
ffffffffc0200f4c:	20878a63          	beq	a5,s0,ffffffffc0201160 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	54b000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f56:	30a99563          	bne	s3,a0,ffffffffc0201260 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f5a:	4505                	li	a0,1
ffffffffc0200f5c:	541000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f60:	2e051063          	bnez	a0,ffffffffc0201240 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f64:	481c                	lw	a5,16(s0)
ffffffffc0200f66:	2a079d63          	bnez	a5,ffffffffc0201220 <default_check+0x422>
    free_page(p);
ffffffffc0200f6a:	854e                	mv	a0,s3
ffffffffc0200f6c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f6e:	01843023          	sd	s8,0(s0)
ffffffffc0200f72:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f76:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f7a:	561000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_page(p1);
ffffffffc0200f7e:	4585                	li	a1,1
ffffffffc0200f80:	8556                	mv	a0,s5
ffffffffc0200f82:	559000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_page(p2);
ffffffffc0200f86:	4585                	li	a1,1
ffffffffc0200f88:	8552                	mv	a0,s4
ffffffffc0200f8a:	551000ef          	jal	ra,ffffffffc0201cda <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f8e:	4515                	li	a0,5
ffffffffc0200f90:	50d000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200f94:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f96:	26050563          	beqz	a0,ffffffffc0201200 <default_check+0x402>
ffffffffc0200f9a:	651c                	ld	a5,8(a0)
ffffffffc0200f9c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f9e:	8b85                	andi	a5,a5,1
ffffffffc0200fa0:	54079063          	bnez	a5,ffffffffc02014e0 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fa4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fa6:	00043b03          	ld	s6,0(s0)
ffffffffc0200faa:	00843a83          	ld	s5,8(s0)
ffffffffc0200fae:	e000                	sd	s0,0(s0)
ffffffffc0200fb0:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fb2:	4eb000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200fb6:	50051563          	bnez	a0,ffffffffc02014c0 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fba:	08098a13          	addi	s4,s3,128
ffffffffc0200fbe:	8552                	mv	a0,s4
ffffffffc0200fc0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fc2:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fc6:	00008797          	auipc	a5,0x8
ffffffffc0200fca:	4607ad23          	sw	zero,1146(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fce:	50d000ef          	jal	ra,ffffffffc0201cda <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fd2:	4511                	li	a0,4
ffffffffc0200fd4:	4c9000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200fd8:	4c051463          	bnez	a0,ffffffffc02014a0 <default_check+0x6a2>
ffffffffc0200fdc:	0889b783          	ld	a5,136(s3)
ffffffffc0200fe0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200fe2:	8b85                	andi	a5,a5,1
ffffffffc0200fe4:	48078e63          	beqz	a5,ffffffffc0201480 <default_check+0x682>
ffffffffc0200fe8:	0909a703          	lw	a4,144(s3)
ffffffffc0200fec:	478d                	li	a5,3
ffffffffc0200fee:	48f71963          	bne	a4,a5,ffffffffc0201480 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ff2:	450d                	li	a0,3
ffffffffc0200ff4:	4a9000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0200ff8:	8c2a                	mv	s8,a0
ffffffffc0200ffa:	46050363          	beqz	a0,ffffffffc0201460 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200ffe:	4505                	li	a0,1
ffffffffc0201000:	49d000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0201004:	42051e63          	bnez	a0,ffffffffc0201440 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201008:	418a1c63          	bne	s4,s8,ffffffffc0201420 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020100c:	4585                	li	a1,1
ffffffffc020100e:	854e                	mv	a0,s3
ffffffffc0201010:	4cb000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_pages(p1, 3);
ffffffffc0201014:	458d                	li	a1,3
ffffffffc0201016:	8552                	mv	a0,s4
ffffffffc0201018:	4c3000ef          	jal	ra,ffffffffc0201cda <free_pages>
ffffffffc020101c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201020:	04098c13          	addi	s8,s3,64
ffffffffc0201024:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201026:	8b85                	andi	a5,a5,1
ffffffffc0201028:	3c078c63          	beqz	a5,ffffffffc0201400 <default_check+0x602>
ffffffffc020102c:	0109a703          	lw	a4,16(s3)
ffffffffc0201030:	4785                	li	a5,1
ffffffffc0201032:	3cf71763          	bne	a4,a5,ffffffffc0201400 <default_check+0x602>
ffffffffc0201036:	008a3783          	ld	a5,8(s4)
ffffffffc020103a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020103c:	8b85                	andi	a5,a5,1
ffffffffc020103e:	3a078163          	beqz	a5,ffffffffc02013e0 <default_check+0x5e2>
ffffffffc0201042:	010a2703          	lw	a4,16(s4)
ffffffffc0201046:	478d                	li	a5,3
ffffffffc0201048:	38f71c63          	bne	a4,a5,ffffffffc02013e0 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	44f000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0201052:	36a99763          	bne	s3,a0,ffffffffc02013c0 <default_check+0x5c2>
    free_page(p0);
ffffffffc0201056:	4585                	li	a1,1
ffffffffc0201058:	483000ef          	jal	ra,ffffffffc0201cda <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020105c:	4509                	li	a0,2
ffffffffc020105e:	43f000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0201062:	32aa1f63          	bne	s4,a0,ffffffffc02013a0 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201066:	4589                	li	a1,2
ffffffffc0201068:	473000ef          	jal	ra,ffffffffc0201cda <free_pages>
    free_page(p2);
ffffffffc020106c:	4585                	li	a1,1
ffffffffc020106e:	8562                	mv	a0,s8
ffffffffc0201070:	46b000ef          	jal	ra,ffffffffc0201cda <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201074:	4515                	li	a0,5
ffffffffc0201076:	427000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc020107a:	89aa                	mv	s3,a0
ffffffffc020107c:	48050263          	beqz	a0,ffffffffc0201500 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201080:	4505                	li	a0,1
ffffffffc0201082:	41b000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
ffffffffc0201086:	2c051d63          	bnez	a0,ffffffffc0201360 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020108a:	481c                	lw	a5,16(s0)
ffffffffc020108c:	2a079a63          	bnez	a5,ffffffffc0201340 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201090:	4595                	li	a1,5
ffffffffc0201092:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201094:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201098:	01643023          	sd	s6,0(s0)
ffffffffc020109c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02010a0:	43b000ef          	jal	ra,ffffffffc0201cda <free_pages>
    return listelm->next;
ffffffffc02010a4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010a6:	00878963          	beq	a5,s0,ffffffffc02010b8 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010aa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010ae:	679c                	ld	a5,8(a5)
ffffffffc02010b0:	397d                	addiw	s2,s2,-1
ffffffffc02010b2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010b4:	fe879be3          	bne	a5,s0,ffffffffc02010aa <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010b8:	26091463          	bnez	s2,ffffffffc0201320 <default_check+0x522>
    assert(total == 0);
ffffffffc02010bc:	46049263          	bnez	s1,ffffffffc0201520 <default_check+0x722>
}
ffffffffc02010c0:	60a6                	ld	ra,72(sp)
ffffffffc02010c2:	6406                	ld	s0,64(sp)
ffffffffc02010c4:	74e2                	ld	s1,56(sp)
ffffffffc02010c6:	7942                	ld	s2,48(sp)
ffffffffc02010c8:	79a2                	ld	s3,40(sp)
ffffffffc02010ca:	7a02                	ld	s4,32(sp)
ffffffffc02010cc:	6ae2                	ld	s5,24(sp)
ffffffffc02010ce:	6b42                	ld	s6,16(sp)
ffffffffc02010d0:	6ba2                	ld	s7,8(sp)
ffffffffc02010d2:	6c02                	ld	s8,0(sp)
ffffffffc02010d4:	6161                	addi	sp,sp,80
ffffffffc02010d6:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010d8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010da:	4481                	li	s1,0
ffffffffc02010dc:	4901                	li	s2,0
ffffffffc02010de:	b38d                	j	ffffffffc0200e40 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010e0:	00004697          	auipc	a3,0x4
ffffffffc02010e4:	87068693          	addi	a3,a3,-1936 # ffffffffc0204950 <commands+0x808>
ffffffffc02010e8:	00004617          	auipc	a2,0x4
ffffffffc02010ec:	87860613          	addi	a2,a2,-1928 # ffffffffc0204960 <commands+0x818>
ffffffffc02010f0:	0f000593          	li	a1,240
ffffffffc02010f4:	00004517          	auipc	a0,0x4
ffffffffc02010f8:	88450513          	addi	a0,a0,-1916 # ffffffffc0204978 <commands+0x830>
ffffffffc02010fc:	b5eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201100:	00004697          	auipc	a3,0x4
ffffffffc0201104:	91068693          	addi	a3,a3,-1776 # ffffffffc0204a10 <commands+0x8c8>
ffffffffc0201108:	00004617          	auipc	a2,0x4
ffffffffc020110c:	85860613          	addi	a2,a2,-1960 # ffffffffc0204960 <commands+0x818>
ffffffffc0201110:	0bd00593          	li	a1,189
ffffffffc0201114:	00004517          	auipc	a0,0x4
ffffffffc0201118:	86450513          	addi	a0,a0,-1948 # ffffffffc0204978 <commands+0x830>
ffffffffc020111c:	b3eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201120:	00004697          	auipc	a3,0x4
ffffffffc0201124:	91868693          	addi	a3,a3,-1768 # ffffffffc0204a38 <commands+0x8f0>
ffffffffc0201128:	00004617          	auipc	a2,0x4
ffffffffc020112c:	83860613          	addi	a2,a2,-1992 # ffffffffc0204960 <commands+0x818>
ffffffffc0201130:	0be00593          	li	a1,190
ffffffffc0201134:	00004517          	auipc	a0,0x4
ffffffffc0201138:	84450513          	addi	a0,a0,-1980 # ffffffffc0204978 <commands+0x830>
ffffffffc020113c:	b1eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201140:	00004697          	auipc	a3,0x4
ffffffffc0201144:	93868693          	addi	a3,a3,-1736 # ffffffffc0204a78 <commands+0x930>
ffffffffc0201148:	00004617          	auipc	a2,0x4
ffffffffc020114c:	81860613          	addi	a2,a2,-2024 # ffffffffc0204960 <commands+0x818>
ffffffffc0201150:	0c000593          	li	a1,192
ffffffffc0201154:	00004517          	auipc	a0,0x4
ffffffffc0201158:	82450513          	addi	a0,a0,-2012 # ffffffffc0204978 <commands+0x830>
ffffffffc020115c:	afeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201160:	00004697          	auipc	a3,0x4
ffffffffc0201164:	9a068693          	addi	a3,a3,-1632 # ffffffffc0204b00 <commands+0x9b8>
ffffffffc0201168:	00003617          	auipc	a2,0x3
ffffffffc020116c:	7f860613          	addi	a2,a2,2040 # ffffffffc0204960 <commands+0x818>
ffffffffc0201170:	0d900593          	li	a1,217
ffffffffc0201174:	00004517          	auipc	a0,0x4
ffffffffc0201178:	80450513          	addi	a0,a0,-2044 # ffffffffc0204978 <commands+0x830>
ffffffffc020117c:	adeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201180:	00004697          	auipc	a3,0x4
ffffffffc0201184:	83068693          	addi	a3,a3,-2000 # ffffffffc02049b0 <commands+0x868>
ffffffffc0201188:	00003617          	auipc	a2,0x3
ffffffffc020118c:	7d860613          	addi	a2,a2,2008 # ffffffffc0204960 <commands+0x818>
ffffffffc0201190:	0d200593          	li	a1,210
ffffffffc0201194:	00003517          	auipc	a0,0x3
ffffffffc0201198:	7e450513          	addi	a0,a0,2020 # ffffffffc0204978 <commands+0x830>
ffffffffc020119c:	abeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc02011a0:	00004697          	auipc	a3,0x4
ffffffffc02011a4:	95068693          	addi	a3,a3,-1712 # ffffffffc0204af0 <commands+0x9a8>
ffffffffc02011a8:	00003617          	auipc	a2,0x3
ffffffffc02011ac:	7b860613          	addi	a2,a2,1976 # ffffffffc0204960 <commands+0x818>
ffffffffc02011b0:	0d000593          	li	a1,208
ffffffffc02011b4:	00003517          	auipc	a0,0x3
ffffffffc02011b8:	7c450513          	addi	a0,a0,1988 # ffffffffc0204978 <commands+0x830>
ffffffffc02011bc:	a9eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c0:	00004697          	auipc	a3,0x4
ffffffffc02011c4:	91868693          	addi	a3,a3,-1768 # ffffffffc0204ad8 <commands+0x990>
ffffffffc02011c8:	00003617          	auipc	a2,0x3
ffffffffc02011cc:	79860613          	addi	a2,a2,1944 # ffffffffc0204960 <commands+0x818>
ffffffffc02011d0:	0cb00593          	li	a1,203
ffffffffc02011d4:	00003517          	auipc	a0,0x3
ffffffffc02011d8:	7a450513          	addi	a0,a0,1956 # ffffffffc0204978 <commands+0x830>
ffffffffc02011dc:	a7eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011e0:	00004697          	auipc	a3,0x4
ffffffffc02011e4:	8d868693          	addi	a3,a3,-1832 # ffffffffc0204ab8 <commands+0x970>
ffffffffc02011e8:	00003617          	auipc	a2,0x3
ffffffffc02011ec:	77860613          	addi	a2,a2,1912 # ffffffffc0204960 <commands+0x818>
ffffffffc02011f0:	0c200593          	li	a1,194
ffffffffc02011f4:	00003517          	auipc	a0,0x3
ffffffffc02011f8:	78450513          	addi	a0,a0,1924 # ffffffffc0204978 <commands+0x830>
ffffffffc02011fc:	a5eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc0201200:	00004697          	auipc	a3,0x4
ffffffffc0201204:	94868693          	addi	a3,a3,-1720 # ffffffffc0204b48 <commands+0xa00>
ffffffffc0201208:	00003617          	auipc	a2,0x3
ffffffffc020120c:	75860613          	addi	a2,a2,1880 # ffffffffc0204960 <commands+0x818>
ffffffffc0201210:	0f800593          	li	a1,248
ffffffffc0201214:	00003517          	auipc	a0,0x3
ffffffffc0201218:	76450513          	addi	a0,a0,1892 # ffffffffc0204978 <commands+0x830>
ffffffffc020121c:	a3eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201220:	00004697          	auipc	a3,0x4
ffffffffc0201224:	91868693          	addi	a3,a3,-1768 # ffffffffc0204b38 <commands+0x9f0>
ffffffffc0201228:	00003617          	auipc	a2,0x3
ffffffffc020122c:	73860613          	addi	a2,a2,1848 # ffffffffc0204960 <commands+0x818>
ffffffffc0201230:	0df00593          	li	a1,223
ffffffffc0201234:	00003517          	auipc	a0,0x3
ffffffffc0201238:	74450513          	addi	a0,a0,1860 # ffffffffc0204978 <commands+0x830>
ffffffffc020123c:	a1eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201240:	00004697          	auipc	a3,0x4
ffffffffc0201244:	89868693          	addi	a3,a3,-1896 # ffffffffc0204ad8 <commands+0x990>
ffffffffc0201248:	00003617          	auipc	a2,0x3
ffffffffc020124c:	71860613          	addi	a2,a2,1816 # ffffffffc0204960 <commands+0x818>
ffffffffc0201250:	0dd00593          	li	a1,221
ffffffffc0201254:	00003517          	auipc	a0,0x3
ffffffffc0201258:	72450513          	addi	a0,a0,1828 # ffffffffc0204978 <commands+0x830>
ffffffffc020125c:	9feff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201260:	00004697          	auipc	a3,0x4
ffffffffc0201264:	8b868693          	addi	a3,a3,-1864 # ffffffffc0204b18 <commands+0x9d0>
ffffffffc0201268:	00003617          	auipc	a2,0x3
ffffffffc020126c:	6f860613          	addi	a2,a2,1784 # ffffffffc0204960 <commands+0x818>
ffffffffc0201270:	0dc00593          	li	a1,220
ffffffffc0201274:	00003517          	auipc	a0,0x3
ffffffffc0201278:	70450513          	addi	a0,a0,1796 # ffffffffc0204978 <commands+0x830>
ffffffffc020127c:	9deff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201280:	00003697          	auipc	a3,0x3
ffffffffc0201284:	73068693          	addi	a3,a3,1840 # ffffffffc02049b0 <commands+0x868>
ffffffffc0201288:	00003617          	auipc	a2,0x3
ffffffffc020128c:	6d860613          	addi	a2,a2,1752 # ffffffffc0204960 <commands+0x818>
ffffffffc0201290:	0b900593          	li	a1,185
ffffffffc0201294:	00003517          	auipc	a0,0x3
ffffffffc0201298:	6e450513          	addi	a0,a0,1764 # ffffffffc0204978 <commands+0x830>
ffffffffc020129c:	9beff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012a0:	00004697          	auipc	a3,0x4
ffffffffc02012a4:	83868693          	addi	a3,a3,-1992 # ffffffffc0204ad8 <commands+0x990>
ffffffffc02012a8:	00003617          	auipc	a2,0x3
ffffffffc02012ac:	6b860613          	addi	a2,a2,1720 # ffffffffc0204960 <commands+0x818>
ffffffffc02012b0:	0d600593          	li	a1,214
ffffffffc02012b4:	00003517          	auipc	a0,0x3
ffffffffc02012b8:	6c450513          	addi	a0,a0,1732 # ffffffffc0204978 <commands+0x830>
ffffffffc02012bc:	99eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012c0:	00003697          	auipc	a3,0x3
ffffffffc02012c4:	73068693          	addi	a3,a3,1840 # ffffffffc02049f0 <commands+0x8a8>
ffffffffc02012c8:	00003617          	auipc	a2,0x3
ffffffffc02012cc:	69860613          	addi	a2,a2,1688 # ffffffffc0204960 <commands+0x818>
ffffffffc02012d0:	0d400593          	li	a1,212
ffffffffc02012d4:	00003517          	auipc	a0,0x3
ffffffffc02012d8:	6a450513          	addi	a0,a0,1700 # ffffffffc0204978 <commands+0x830>
ffffffffc02012dc:	97eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012e0:	00003697          	auipc	a3,0x3
ffffffffc02012e4:	6f068693          	addi	a3,a3,1776 # ffffffffc02049d0 <commands+0x888>
ffffffffc02012e8:	00003617          	auipc	a2,0x3
ffffffffc02012ec:	67860613          	addi	a2,a2,1656 # ffffffffc0204960 <commands+0x818>
ffffffffc02012f0:	0d300593          	li	a1,211
ffffffffc02012f4:	00003517          	auipc	a0,0x3
ffffffffc02012f8:	68450513          	addi	a0,a0,1668 # ffffffffc0204978 <commands+0x830>
ffffffffc02012fc:	95eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201300:	00003697          	auipc	a3,0x3
ffffffffc0201304:	6f068693          	addi	a3,a3,1776 # ffffffffc02049f0 <commands+0x8a8>
ffffffffc0201308:	00003617          	auipc	a2,0x3
ffffffffc020130c:	65860613          	addi	a2,a2,1624 # ffffffffc0204960 <commands+0x818>
ffffffffc0201310:	0bb00593          	li	a1,187
ffffffffc0201314:	00003517          	auipc	a0,0x3
ffffffffc0201318:	66450513          	addi	a0,a0,1636 # ffffffffc0204978 <commands+0x830>
ffffffffc020131c:	93eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc0201320:	00004697          	auipc	a3,0x4
ffffffffc0201324:	97868693          	addi	a3,a3,-1672 # ffffffffc0204c98 <commands+0xb50>
ffffffffc0201328:	00003617          	auipc	a2,0x3
ffffffffc020132c:	63860613          	addi	a2,a2,1592 # ffffffffc0204960 <commands+0x818>
ffffffffc0201330:	12500593          	li	a1,293
ffffffffc0201334:	00003517          	auipc	a0,0x3
ffffffffc0201338:	64450513          	addi	a0,a0,1604 # ffffffffc0204978 <commands+0x830>
ffffffffc020133c:	91eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201340:	00003697          	auipc	a3,0x3
ffffffffc0201344:	7f868693          	addi	a3,a3,2040 # ffffffffc0204b38 <commands+0x9f0>
ffffffffc0201348:	00003617          	auipc	a2,0x3
ffffffffc020134c:	61860613          	addi	a2,a2,1560 # ffffffffc0204960 <commands+0x818>
ffffffffc0201350:	11a00593          	li	a1,282
ffffffffc0201354:	00003517          	auipc	a0,0x3
ffffffffc0201358:	62450513          	addi	a0,a0,1572 # ffffffffc0204978 <commands+0x830>
ffffffffc020135c:	8feff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201360:	00003697          	auipc	a3,0x3
ffffffffc0201364:	77868693          	addi	a3,a3,1912 # ffffffffc0204ad8 <commands+0x990>
ffffffffc0201368:	00003617          	auipc	a2,0x3
ffffffffc020136c:	5f860613          	addi	a2,a2,1528 # ffffffffc0204960 <commands+0x818>
ffffffffc0201370:	11800593          	li	a1,280
ffffffffc0201374:	00003517          	auipc	a0,0x3
ffffffffc0201378:	60450513          	addi	a0,a0,1540 # ffffffffc0204978 <commands+0x830>
ffffffffc020137c:	8deff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201380:	00003697          	auipc	a3,0x3
ffffffffc0201384:	71868693          	addi	a3,a3,1816 # ffffffffc0204a98 <commands+0x950>
ffffffffc0201388:	00003617          	auipc	a2,0x3
ffffffffc020138c:	5d860613          	addi	a2,a2,1496 # ffffffffc0204960 <commands+0x818>
ffffffffc0201390:	0c100593          	li	a1,193
ffffffffc0201394:	00003517          	auipc	a0,0x3
ffffffffc0201398:	5e450513          	addi	a0,a0,1508 # ffffffffc0204978 <commands+0x830>
ffffffffc020139c:	8beff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013a0:	00004697          	auipc	a3,0x4
ffffffffc02013a4:	8b868693          	addi	a3,a3,-1864 # ffffffffc0204c58 <commands+0xb10>
ffffffffc02013a8:	00003617          	auipc	a2,0x3
ffffffffc02013ac:	5b860613          	addi	a2,a2,1464 # ffffffffc0204960 <commands+0x818>
ffffffffc02013b0:	11200593          	li	a1,274
ffffffffc02013b4:	00003517          	auipc	a0,0x3
ffffffffc02013b8:	5c450513          	addi	a0,a0,1476 # ffffffffc0204978 <commands+0x830>
ffffffffc02013bc:	89eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013c0:	00004697          	auipc	a3,0x4
ffffffffc02013c4:	87868693          	addi	a3,a3,-1928 # ffffffffc0204c38 <commands+0xaf0>
ffffffffc02013c8:	00003617          	auipc	a2,0x3
ffffffffc02013cc:	59860613          	addi	a2,a2,1432 # ffffffffc0204960 <commands+0x818>
ffffffffc02013d0:	11000593          	li	a1,272
ffffffffc02013d4:	00003517          	auipc	a0,0x3
ffffffffc02013d8:	5a450513          	addi	a0,a0,1444 # ffffffffc0204978 <commands+0x830>
ffffffffc02013dc:	87eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013e0:	00004697          	auipc	a3,0x4
ffffffffc02013e4:	83068693          	addi	a3,a3,-2000 # ffffffffc0204c10 <commands+0xac8>
ffffffffc02013e8:	00003617          	auipc	a2,0x3
ffffffffc02013ec:	57860613          	addi	a2,a2,1400 # ffffffffc0204960 <commands+0x818>
ffffffffc02013f0:	10e00593          	li	a1,270
ffffffffc02013f4:	00003517          	auipc	a0,0x3
ffffffffc02013f8:	58450513          	addi	a0,a0,1412 # ffffffffc0204978 <commands+0x830>
ffffffffc02013fc:	85eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201400:	00003697          	auipc	a3,0x3
ffffffffc0201404:	7e868693          	addi	a3,a3,2024 # ffffffffc0204be8 <commands+0xaa0>
ffffffffc0201408:	00003617          	auipc	a2,0x3
ffffffffc020140c:	55860613          	addi	a2,a2,1368 # ffffffffc0204960 <commands+0x818>
ffffffffc0201410:	10d00593          	li	a1,269
ffffffffc0201414:	00003517          	auipc	a0,0x3
ffffffffc0201418:	56450513          	addi	a0,a0,1380 # ffffffffc0204978 <commands+0x830>
ffffffffc020141c:	83eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201420:	00003697          	auipc	a3,0x3
ffffffffc0201424:	7b868693          	addi	a3,a3,1976 # ffffffffc0204bd8 <commands+0xa90>
ffffffffc0201428:	00003617          	auipc	a2,0x3
ffffffffc020142c:	53860613          	addi	a2,a2,1336 # ffffffffc0204960 <commands+0x818>
ffffffffc0201430:	10800593          	li	a1,264
ffffffffc0201434:	00003517          	auipc	a0,0x3
ffffffffc0201438:	54450513          	addi	a0,a0,1348 # ffffffffc0204978 <commands+0x830>
ffffffffc020143c:	81eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201440:	00003697          	auipc	a3,0x3
ffffffffc0201444:	69868693          	addi	a3,a3,1688 # ffffffffc0204ad8 <commands+0x990>
ffffffffc0201448:	00003617          	auipc	a2,0x3
ffffffffc020144c:	51860613          	addi	a2,a2,1304 # ffffffffc0204960 <commands+0x818>
ffffffffc0201450:	10700593          	li	a1,263
ffffffffc0201454:	00003517          	auipc	a0,0x3
ffffffffc0201458:	52450513          	addi	a0,a0,1316 # ffffffffc0204978 <commands+0x830>
ffffffffc020145c:	ffffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201460:	00003697          	auipc	a3,0x3
ffffffffc0201464:	75868693          	addi	a3,a3,1880 # ffffffffc0204bb8 <commands+0xa70>
ffffffffc0201468:	00003617          	auipc	a2,0x3
ffffffffc020146c:	4f860613          	addi	a2,a2,1272 # ffffffffc0204960 <commands+0x818>
ffffffffc0201470:	10600593          	li	a1,262
ffffffffc0201474:	00003517          	auipc	a0,0x3
ffffffffc0201478:	50450513          	addi	a0,a0,1284 # ffffffffc0204978 <commands+0x830>
ffffffffc020147c:	fdffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201480:	00003697          	auipc	a3,0x3
ffffffffc0201484:	70868693          	addi	a3,a3,1800 # ffffffffc0204b88 <commands+0xa40>
ffffffffc0201488:	00003617          	auipc	a2,0x3
ffffffffc020148c:	4d860613          	addi	a2,a2,1240 # ffffffffc0204960 <commands+0x818>
ffffffffc0201490:	10500593          	li	a1,261
ffffffffc0201494:	00003517          	auipc	a0,0x3
ffffffffc0201498:	4e450513          	addi	a0,a0,1252 # ffffffffc0204978 <commands+0x830>
ffffffffc020149c:	fbffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014a0:	00003697          	auipc	a3,0x3
ffffffffc02014a4:	6d068693          	addi	a3,a3,1744 # ffffffffc0204b70 <commands+0xa28>
ffffffffc02014a8:	00003617          	auipc	a2,0x3
ffffffffc02014ac:	4b860613          	addi	a2,a2,1208 # ffffffffc0204960 <commands+0x818>
ffffffffc02014b0:	10400593          	li	a1,260
ffffffffc02014b4:	00003517          	auipc	a0,0x3
ffffffffc02014b8:	4c450513          	addi	a0,a0,1220 # ffffffffc0204978 <commands+0x830>
ffffffffc02014bc:	f9ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014c0:	00003697          	auipc	a3,0x3
ffffffffc02014c4:	61868693          	addi	a3,a3,1560 # ffffffffc0204ad8 <commands+0x990>
ffffffffc02014c8:	00003617          	auipc	a2,0x3
ffffffffc02014cc:	49860613          	addi	a2,a2,1176 # ffffffffc0204960 <commands+0x818>
ffffffffc02014d0:	0fe00593          	li	a1,254
ffffffffc02014d4:	00003517          	auipc	a0,0x3
ffffffffc02014d8:	4a450513          	addi	a0,a0,1188 # ffffffffc0204978 <commands+0x830>
ffffffffc02014dc:	f7ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014e0:	00003697          	auipc	a3,0x3
ffffffffc02014e4:	67868693          	addi	a3,a3,1656 # ffffffffc0204b58 <commands+0xa10>
ffffffffc02014e8:	00003617          	auipc	a2,0x3
ffffffffc02014ec:	47860613          	addi	a2,a2,1144 # ffffffffc0204960 <commands+0x818>
ffffffffc02014f0:	0f900593          	li	a1,249
ffffffffc02014f4:	00003517          	auipc	a0,0x3
ffffffffc02014f8:	48450513          	addi	a0,a0,1156 # ffffffffc0204978 <commands+0x830>
ffffffffc02014fc:	f5ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201500:	00003697          	auipc	a3,0x3
ffffffffc0201504:	77868693          	addi	a3,a3,1912 # ffffffffc0204c78 <commands+0xb30>
ffffffffc0201508:	00003617          	auipc	a2,0x3
ffffffffc020150c:	45860613          	addi	a2,a2,1112 # ffffffffc0204960 <commands+0x818>
ffffffffc0201510:	11700593          	li	a1,279
ffffffffc0201514:	00003517          	auipc	a0,0x3
ffffffffc0201518:	46450513          	addi	a0,a0,1124 # ffffffffc0204978 <commands+0x830>
ffffffffc020151c:	f3ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc0201520:	00003697          	auipc	a3,0x3
ffffffffc0201524:	78868693          	addi	a3,a3,1928 # ffffffffc0204ca8 <commands+0xb60>
ffffffffc0201528:	00003617          	auipc	a2,0x3
ffffffffc020152c:	43860613          	addi	a2,a2,1080 # ffffffffc0204960 <commands+0x818>
ffffffffc0201530:	12600593          	li	a1,294
ffffffffc0201534:	00003517          	auipc	a0,0x3
ffffffffc0201538:	44450513          	addi	a0,a0,1092 # ffffffffc0204978 <commands+0x830>
ffffffffc020153c:	f1ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201540:	00003697          	auipc	a3,0x3
ffffffffc0201544:	45068693          	addi	a3,a3,1104 # ffffffffc0204990 <commands+0x848>
ffffffffc0201548:	00003617          	auipc	a2,0x3
ffffffffc020154c:	41860613          	addi	a2,a2,1048 # ffffffffc0204960 <commands+0x818>
ffffffffc0201550:	0f300593          	li	a1,243
ffffffffc0201554:	00003517          	auipc	a0,0x3
ffffffffc0201558:	42450513          	addi	a0,a0,1060 # ffffffffc0204978 <commands+0x830>
ffffffffc020155c:	efffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201560:	00003697          	auipc	a3,0x3
ffffffffc0201564:	47068693          	addi	a3,a3,1136 # ffffffffc02049d0 <commands+0x888>
ffffffffc0201568:	00003617          	auipc	a2,0x3
ffffffffc020156c:	3f860613          	addi	a2,a2,1016 # ffffffffc0204960 <commands+0x818>
ffffffffc0201570:	0ba00593          	li	a1,186
ffffffffc0201574:	00003517          	auipc	a0,0x3
ffffffffc0201578:	40450513          	addi	a0,a0,1028 # ffffffffc0204978 <commands+0x830>
ffffffffc020157c:	edffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201580 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201580:	1141                	addi	sp,sp,-16
ffffffffc0201582:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201584:	14058463          	beqz	a1,ffffffffc02016cc <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0201588:	00659693          	slli	a3,a1,0x6
ffffffffc020158c:	96aa                	add	a3,a3,a0
ffffffffc020158e:	87aa                	mv	a5,a0
ffffffffc0201590:	02d50263          	beq	a0,a3,ffffffffc02015b4 <default_free_pages+0x34>
ffffffffc0201594:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201596:	8b05                	andi	a4,a4,1
ffffffffc0201598:	10071a63          	bnez	a4,ffffffffc02016ac <default_free_pages+0x12c>
ffffffffc020159c:	6798                	ld	a4,8(a5)
ffffffffc020159e:	8b09                	andi	a4,a4,2
ffffffffc02015a0:	10071663          	bnez	a4,ffffffffc02016ac <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015a4:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02015a8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015ac:	04078793          	addi	a5,a5,64
ffffffffc02015b0:	fed792e3          	bne	a5,a3,ffffffffc0201594 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015b4:	2581                	sext.w	a1,a1
ffffffffc02015b6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015b8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015bc:	4789                	li	a5,2
ffffffffc02015be:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015c2:	00008697          	auipc	a3,0x8
ffffffffc02015c6:	e6e68693          	addi	a3,a3,-402 # ffffffffc0209430 <free_area>
ffffffffc02015ca:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015cc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015ce:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015d2:	9db9                	addw	a1,a1,a4
ffffffffc02015d4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015d6:	0ad78463          	beq	a5,a3,ffffffffc020167e <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02015da:	fe878713          	addi	a4,a5,-24
ffffffffc02015de:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015e2:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015e4:	00e56a63          	bltu	a0,a4,ffffffffc02015f8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02015e8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015ea:	04d70c63          	beq	a4,a3,ffffffffc0201642 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc02015ee:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015f0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015f4:	fee57ae3          	bgeu	a0,a4,ffffffffc02015e8 <default_free_pages+0x68>
ffffffffc02015f8:	c199                	beqz	a1,ffffffffc02015fe <default_free_pages+0x7e>
ffffffffc02015fa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015fe:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201600:	e390                	sd	a2,0(a5)
ffffffffc0201602:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201604:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201606:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201608:	00d70d63          	beq	a4,a3,ffffffffc0201622 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc020160c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201610:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201614:	02059813          	slli	a6,a1,0x20
ffffffffc0201618:	01a85793          	srli	a5,a6,0x1a
ffffffffc020161c:	97b2                	add	a5,a5,a2
ffffffffc020161e:	02f50c63          	beq	a0,a5,ffffffffc0201656 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201622:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201624:	00d78c63          	beq	a5,a3,ffffffffc020163c <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201628:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020162a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc020162e:	02061593          	slli	a1,a2,0x20
ffffffffc0201632:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201636:	972a                	add	a4,a4,a0
ffffffffc0201638:	04e68a63          	beq	a3,a4,ffffffffc020168c <default_free_pages+0x10c>
}
ffffffffc020163c:	60a2                	ld	ra,8(sp)
ffffffffc020163e:	0141                	addi	sp,sp,16
ffffffffc0201640:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201642:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201644:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201646:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201648:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020164a:	02d70763          	beq	a4,a3,ffffffffc0201678 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020164e:	8832                	mv	a6,a2
ffffffffc0201650:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201652:	87ba                	mv	a5,a4
ffffffffc0201654:	bf71                	j	ffffffffc02015f0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201656:	491c                	lw	a5,16(a0)
ffffffffc0201658:	9dbd                	addw	a1,a1,a5
ffffffffc020165a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020165e:	57f5                	li	a5,-3
ffffffffc0201660:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201664:	01853803          	ld	a6,24(a0)
ffffffffc0201668:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020166a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020166c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201670:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201672:	0105b023          	sd	a6,0(a1)
ffffffffc0201676:	b77d                	j	ffffffffc0201624 <default_free_pages+0xa4>
ffffffffc0201678:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020167a:	873e                	mv	a4,a5
ffffffffc020167c:	bf41                	j	ffffffffc020160c <default_free_pages+0x8c>
}
ffffffffc020167e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201680:	e390                	sd	a2,0(a5)
ffffffffc0201682:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201684:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201686:	ed1c                	sd	a5,24(a0)
ffffffffc0201688:	0141                	addi	sp,sp,16
ffffffffc020168a:	8082                	ret
            base->property += p->property;
ffffffffc020168c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201690:	ff078693          	addi	a3,a5,-16
ffffffffc0201694:	9e39                	addw	a2,a2,a4
ffffffffc0201696:	c910                	sw	a2,16(a0)
ffffffffc0201698:	5775                	li	a4,-3
ffffffffc020169a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020169e:	6398                	ld	a4,0(a5)
ffffffffc02016a0:	679c                	ld	a5,8(a5)
}
ffffffffc02016a2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016a4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016a6:	e398                	sd	a4,0(a5)
ffffffffc02016a8:	0141                	addi	sp,sp,16
ffffffffc02016aa:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016ac:	00003697          	auipc	a3,0x3
ffffffffc02016b0:	61468693          	addi	a3,a3,1556 # ffffffffc0204cc0 <commands+0xb78>
ffffffffc02016b4:	00003617          	auipc	a2,0x3
ffffffffc02016b8:	2ac60613          	addi	a2,a2,684 # ffffffffc0204960 <commands+0x818>
ffffffffc02016bc:	08300593          	li	a1,131
ffffffffc02016c0:	00003517          	auipc	a0,0x3
ffffffffc02016c4:	2b850513          	addi	a0,a0,696 # ffffffffc0204978 <commands+0x830>
ffffffffc02016c8:	d93fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02016cc:	00003697          	auipc	a3,0x3
ffffffffc02016d0:	5ec68693          	addi	a3,a3,1516 # ffffffffc0204cb8 <commands+0xb70>
ffffffffc02016d4:	00003617          	auipc	a2,0x3
ffffffffc02016d8:	28c60613          	addi	a2,a2,652 # ffffffffc0204960 <commands+0x818>
ffffffffc02016dc:	08000593          	li	a1,128
ffffffffc02016e0:	00003517          	auipc	a0,0x3
ffffffffc02016e4:	29850513          	addi	a0,a0,664 # ffffffffc0204978 <commands+0x830>
ffffffffc02016e8:	d73fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02016ec <default_alloc_pages>:
    assert(n > 0);
ffffffffc02016ec:	c941                	beqz	a0,ffffffffc020177c <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02016ee:	00008597          	auipc	a1,0x8
ffffffffc02016f2:	d4258593          	addi	a1,a1,-702 # ffffffffc0209430 <free_area>
ffffffffc02016f6:	0105a803          	lw	a6,16(a1)
ffffffffc02016fa:	872a                	mv	a4,a0
ffffffffc02016fc:	02081793          	slli	a5,a6,0x20
ffffffffc0201700:	9381                	srli	a5,a5,0x20
ffffffffc0201702:	00a7ee63          	bltu	a5,a0,ffffffffc020171e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201706:	87ae                	mv	a5,a1
ffffffffc0201708:	a801                	j	ffffffffc0201718 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020170a:	ff87a683          	lw	a3,-8(a5)
ffffffffc020170e:	02069613          	slli	a2,a3,0x20
ffffffffc0201712:	9201                	srli	a2,a2,0x20
ffffffffc0201714:	00e67763          	bgeu	a2,a4,ffffffffc0201722 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201718:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020171a:	feb798e3          	bne	a5,a1,ffffffffc020170a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020171e:	4501                	li	a0,0
}
ffffffffc0201720:	8082                	ret
    return listelm->prev;
ffffffffc0201722:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201726:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020172a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020172e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201732:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201736:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020173a:	02c77863          	bgeu	a4,a2,ffffffffc020176a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020173e:	071a                	slli	a4,a4,0x6
ffffffffc0201740:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201742:	41c686bb          	subw	a3,a3,t3
ffffffffc0201746:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201748:	00870613          	addi	a2,a4,8
ffffffffc020174c:	4689                	li	a3,2
ffffffffc020174e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201752:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201756:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020175a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020175e:	e290                	sd	a2,0(a3)
ffffffffc0201760:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201764:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201766:	01173c23          	sd	a7,24(a4)
ffffffffc020176a:	41c8083b          	subw	a6,a6,t3
ffffffffc020176e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201772:	5775                	li	a4,-3
ffffffffc0201774:	17c1                	addi	a5,a5,-16
ffffffffc0201776:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020177a:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020177c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020177e:	00003697          	auipc	a3,0x3
ffffffffc0201782:	53a68693          	addi	a3,a3,1338 # ffffffffc0204cb8 <commands+0xb70>
ffffffffc0201786:	00003617          	auipc	a2,0x3
ffffffffc020178a:	1da60613          	addi	a2,a2,474 # ffffffffc0204960 <commands+0x818>
ffffffffc020178e:	06200593          	li	a1,98
ffffffffc0201792:	00003517          	auipc	a0,0x3
ffffffffc0201796:	1e650513          	addi	a0,a0,486 # ffffffffc0204978 <commands+0x830>
default_alloc_pages(size_t n) {
ffffffffc020179a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020179c:	cbffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02017a0 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017a0:	1141                	addi	sp,sp,-16
ffffffffc02017a2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017a4:	c5f1                	beqz	a1,ffffffffc0201870 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017a6:	00659693          	slli	a3,a1,0x6
ffffffffc02017aa:	96aa                	add	a3,a3,a0
ffffffffc02017ac:	87aa                	mv	a5,a0
ffffffffc02017ae:	00d50f63          	beq	a0,a3,ffffffffc02017cc <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017b2:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017b4:	8b05                	andi	a4,a4,1
ffffffffc02017b6:	cf49                	beqz	a4,ffffffffc0201850 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017b8:	0007a823          	sw	zero,16(a5)
ffffffffc02017bc:	0007b423          	sd	zero,8(a5)
ffffffffc02017c0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017c4:	04078793          	addi	a5,a5,64
ffffffffc02017c8:	fed795e3          	bne	a5,a3,ffffffffc02017b2 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017cc:	2581                	sext.w	a1,a1
ffffffffc02017ce:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017d0:	4789                	li	a5,2
ffffffffc02017d2:	00850713          	addi	a4,a0,8
ffffffffc02017d6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017da:	00008697          	auipc	a3,0x8
ffffffffc02017de:	c5668693          	addi	a3,a3,-938 # ffffffffc0209430 <free_area>
ffffffffc02017e2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017e4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017e6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017ea:	9db9                	addw	a1,a1,a4
ffffffffc02017ec:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017ee:	04d78a63          	beq	a5,a3,ffffffffc0201842 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02017f2:	fe878713          	addi	a4,a5,-24
ffffffffc02017f6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02017fa:	4581                	li	a1,0
            if (base < page) {
ffffffffc02017fc:	00e56a63          	bltu	a0,a4,ffffffffc0201810 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201800:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201802:	02d70263          	beq	a4,a3,ffffffffc0201826 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0201806:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201808:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020180c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201800 <default_init_memmap+0x60>
ffffffffc0201810:	c199                	beqz	a1,ffffffffc0201816 <default_init_memmap+0x76>
ffffffffc0201812:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201816:	6398                	ld	a4,0(a5)
}
ffffffffc0201818:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020181a:	e390                	sd	a2,0(a5)
ffffffffc020181c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020181e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201820:	ed18                	sd	a4,24(a0)
ffffffffc0201822:	0141                	addi	sp,sp,16
ffffffffc0201824:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201826:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201828:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020182a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020182c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020182e:	00d70663          	beq	a4,a3,ffffffffc020183a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201832:	8832                	mv	a6,a2
ffffffffc0201834:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201836:	87ba                	mv	a5,a4
ffffffffc0201838:	bfc1                	j	ffffffffc0201808 <default_init_memmap+0x68>
}
ffffffffc020183a:	60a2                	ld	ra,8(sp)
ffffffffc020183c:	e290                	sd	a2,0(a3)
ffffffffc020183e:	0141                	addi	sp,sp,16
ffffffffc0201840:	8082                	ret
ffffffffc0201842:	60a2                	ld	ra,8(sp)
ffffffffc0201844:	e390                	sd	a2,0(a5)
ffffffffc0201846:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201848:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020184a:	ed1c                	sd	a5,24(a0)
ffffffffc020184c:	0141                	addi	sp,sp,16
ffffffffc020184e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201850:	00003697          	auipc	a3,0x3
ffffffffc0201854:	49868693          	addi	a3,a3,1176 # ffffffffc0204ce8 <commands+0xba0>
ffffffffc0201858:	00003617          	auipc	a2,0x3
ffffffffc020185c:	10860613          	addi	a2,a2,264 # ffffffffc0204960 <commands+0x818>
ffffffffc0201860:	04900593          	li	a1,73
ffffffffc0201864:	00003517          	auipc	a0,0x3
ffffffffc0201868:	11450513          	addi	a0,a0,276 # ffffffffc0204978 <commands+0x830>
ffffffffc020186c:	beffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201870:	00003697          	auipc	a3,0x3
ffffffffc0201874:	44868693          	addi	a3,a3,1096 # ffffffffc0204cb8 <commands+0xb70>
ffffffffc0201878:	00003617          	auipc	a2,0x3
ffffffffc020187c:	0e860613          	addi	a2,a2,232 # ffffffffc0204960 <commands+0x818>
ffffffffc0201880:	04600593          	li	a1,70
ffffffffc0201884:	00003517          	auipc	a0,0x3
ffffffffc0201888:	0f450513          	addi	a0,a0,244 # ffffffffc0204978 <commands+0x830>
ffffffffc020188c:	bcffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201890 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201890:	c94d                	beqz	a0,ffffffffc0201942 <slob_free+0xb2>
{
ffffffffc0201892:	1141                	addi	sp,sp,-16
ffffffffc0201894:	e022                	sd	s0,0(sp)
ffffffffc0201896:	e406                	sd	ra,8(sp)
ffffffffc0201898:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020189a:	e9c1                	bnez	a1,ffffffffc020192a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020189c:	100027f3          	csrr	a5,sstatus
ffffffffc02018a0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018a2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018a4:	ebd9                	bnez	a5,ffffffffc020193a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018a6:	00007617          	auipc	a2,0x7
ffffffffc02018aa:	77a60613          	addi	a2,a2,1914 # ffffffffc0209020 <slobfree>
ffffffffc02018ae:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018b0:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018b2:	679c                	ld	a5,8(a5)
ffffffffc02018b4:	02877a63          	bgeu	a4,s0,ffffffffc02018e8 <slob_free+0x58>
ffffffffc02018b8:	00f46463          	bltu	s0,a5,ffffffffc02018c0 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018bc:	fef76ae3          	bltu	a4,a5,ffffffffc02018b0 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018c0:	400c                	lw	a1,0(s0)
ffffffffc02018c2:	00459693          	slli	a3,a1,0x4
ffffffffc02018c6:	96a2                	add	a3,a3,s0
ffffffffc02018c8:	02d78a63          	beq	a5,a3,ffffffffc02018fc <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018cc:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018ce:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018d0:	00469793          	slli	a5,a3,0x4
ffffffffc02018d4:	97ba                	add	a5,a5,a4
ffffffffc02018d6:	02f40e63          	beq	s0,a5,ffffffffc0201912 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018da:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018dc:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018de:	e129                	bnez	a0,ffffffffc0201920 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018e0:	60a2                	ld	ra,8(sp)
ffffffffc02018e2:	6402                	ld	s0,0(sp)
ffffffffc02018e4:	0141                	addi	sp,sp,16
ffffffffc02018e6:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018e8:	fcf764e3          	bltu	a4,a5,ffffffffc02018b0 <slob_free+0x20>
ffffffffc02018ec:	fcf472e3          	bgeu	s0,a5,ffffffffc02018b0 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02018f0:	400c                	lw	a1,0(s0)
ffffffffc02018f2:	00459693          	slli	a3,a1,0x4
ffffffffc02018f6:	96a2                	add	a3,a3,s0
ffffffffc02018f8:	fcd79ae3          	bne	a5,a3,ffffffffc02018cc <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02018fc:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018fe:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201900:	9db5                	addw	a1,a1,a3
ffffffffc0201902:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201904:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201906:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201908:	00469793          	slli	a5,a3,0x4
ffffffffc020190c:	97ba                	add	a5,a5,a4
ffffffffc020190e:	fcf416e3          	bne	s0,a5,ffffffffc02018da <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201912:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201914:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201916:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201918:	9ebd                	addw	a3,a3,a5
ffffffffc020191a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020191c:	e70c                	sd	a1,8(a4)
ffffffffc020191e:	d169                	beqz	a0,ffffffffc02018e0 <slob_free+0x50>
}
ffffffffc0201920:	6402                	ld	s0,0(sp)
ffffffffc0201922:	60a2                	ld	ra,8(sp)
ffffffffc0201924:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201926:	804ff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020192a:	25bd                	addiw	a1,a1,15
ffffffffc020192c:	8191                	srli	a1,a1,0x4
ffffffffc020192e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201930:	100027f3          	csrr	a5,sstatus
ffffffffc0201934:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201936:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201938:	d7bd                	beqz	a5,ffffffffc02018a6 <slob_free+0x16>
        intr_disable();
ffffffffc020193a:	ff7fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc020193e:	4505                	li	a0,1
ffffffffc0201940:	b79d                	j	ffffffffc02018a6 <slob_free+0x16>
ffffffffc0201942:	8082                	ret

ffffffffc0201944 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201944:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201946:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201948:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020194c:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc020194e:	34e000ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
	if (!page)
ffffffffc0201952:	c91d                	beqz	a0,ffffffffc0201988 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201954:	0000c697          	auipc	a3,0xc
ffffffffc0201958:	b646b683          	ld	a3,-1180(a3) # ffffffffc020d4b8 <pages>
ffffffffc020195c:	8d15                	sub	a0,a0,a3
ffffffffc020195e:	8519                	srai	a0,a0,0x6
ffffffffc0201960:	00004697          	auipc	a3,0x4
ffffffffc0201964:	0c86b683          	ld	a3,200(a3) # ffffffffc0205a28 <nbase>
ffffffffc0201968:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020196a:	00c51793          	slli	a5,a0,0xc
ffffffffc020196e:	83b1                	srli	a5,a5,0xc
ffffffffc0201970:	0000c717          	auipc	a4,0xc
ffffffffc0201974:	b4073703          	ld	a4,-1216(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201978:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020197a:	00e7fa63          	bgeu	a5,a4,ffffffffc020198e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020197e:	0000c697          	auipc	a3,0xc
ffffffffc0201982:	b4a6b683          	ld	a3,-1206(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201986:	9536                	add	a0,a0,a3
}
ffffffffc0201988:	60a2                	ld	ra,8(sp)
ffffffffc020198a:	0141                	addi	sp,sp,16
ffffffffc020198c:	8082                	ret
ffffffffc020198e:	86aa                	mv	a3,a0
ffffffffc0201990:	00003617          	auipc	a2,0x3
ffffffffc0201994:	3b860613          	addi	a2,a2,952 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0201998:	07100593          	li	a1,113
ffffffffc020199c:	00003517          	auipc	a0,0x3
ffffffffc02019a0:	3d450513          	addi	a0,a0,980 # ffffffffc0204d70 <default_pmm_manager+0x60>
ffffffffc02019a4:	ab7fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02019a8 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019a8:	1101                	addi	sp,sp,-32
ffffffffc02019aa:	ec06                	sd	ra,24(sp)
ffffffffc02019ac:	e822                	sd	s0,16(sp)
ffffffffc02019ae:	e426                	sd	s1,8(sp)
ffffffffc02019b0:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019b2:	01050713          	addi	a4,a0,16
ffffffffc02019b6:	6785                	lui	a5,0x1
ffffffffc02019b8:	0cf77363          	bgeu	a4,a5,ffffffffc0201a7e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019bc:	00f50493          	addi	s1,a0,15
ffffffffc02019c0:	8091                	srli	s1,s1,0x4
ffffffffc02019c2:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019c4:	10002673          	csrr	a2,sstatus
ffffffffc02019c8:	8a09                	andi	a2,a2,2
ffffffffc02019ca:	e25d                	bnez	a2,ffffffffc0201a70 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019cc:	00007917          	auipc	s2,0x7
ffffffffc02019d0:	65490913          	addi	s2,s2,1620 # ffffffffc0209020 <slobfree>
ffffffffc02019d4:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019d8:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019da:	4398                	lw	a4,0(a5)
ffffffffc02019dc:	08975e63          	bge	a4,s1,ffffffffc0201a78 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019e0:	00d78b63          	beq	a5,a3,ffffffffc02019f6 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019e4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019e6:	4018                	lw	a4,0(s0)
ffffffffc02019e8:	02975a63          	bge	a4,s1,ffffffffc0201a1c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02019ec:	00093683          	ld	a3,0(s2)
ffffffffc02019f0:	87a2                	mv	a5,s0
ffffffffc02019f2:	fed799e3          	bne	a5,a3,ffffffffc02019e4 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019f6:	ee31                	bnez	a2,ffffffffc0201a52 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019f8:	4501                	li	a0,0
ffffffffc02019fa:	f4bff0ef          	jal	ra,ffffffffc0201944 <__slob_get_free_pages.constprop.0>
ffffffffc02019fe:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a00:	cd05                	beqz	a0,ffffffffc0201a38 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a02:	6585                	lui	a1,0x1
ffffffffc0201a04:	e8dff0ef          	jal	ra,ffffffffc0201890 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a08:	10002673          	csrr	a2,sstatus
ffffffffc0201a0c:	8a09                	andi	a2,a2,2
ffffffffc0201a0e:	ee05                	bnez	a2,ffffffffc0201a46 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a10:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a14:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a16:	4018                	lw	a4,0(s0)
ffffffffc0201a18:	fc974ae3          	blt	a4,s1,ffffffffc02019ec <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a1c:	04e48763          	beq	s1,a4,ffffffffc0201a6a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a20:	00449693          	slli	a3,s1,0x4
ffffffffc0201a24:	96a2                	add	a3,a3,s0
ffffffffc0201a26:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a28:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a2a:	9f05                	subw	a4,a4,s1
ffffffffc0201a2c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a2e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a30:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a32:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a36:	e20d                	bnez	a2,ffffffffc0201a58 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a38:	60e2                	ld	ra,24(sp)
ffffffffc0201a3a:	8522                	mv	a0,s0
ffffffffc0201a3c:	6442                	ld	s0,16(sp)
ffffffffc0201a3e:	64a2                	ld	s1,8(sp)
ffffffffc0201a40:	6902                	ld	s2,0(sp)
ffffffffc0201a42:	6105                	addi	sp,sp,32
ffffffffc0201a44:	8082                	ret
        intr_disable();
ffffffffc0201a46:	eebfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a4a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a4e:	4605                	li	a2,1
ffffffffc0201a50:	b7d1                	j	ffffffffc0201a14 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a52:	ed9fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a56:	b74d                	j	ffffffffc02019f8 <slob_alloc.constprop.0+0x50>
ffffffffc0201a58:	ed3fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a5c:	60e2                	ld	ra,24(sp)
ffffffffc0201a5e:	8522                	mv	a0,s0
ffffffffc0201a60:	6442                	ld	s0,16(sp)
ffffffffc0201a62:	64a2                	ld	s1,8(sp)
ffffffffc0201a64:	6902                	ld	s2,0(sp)
ffffffffc0201a66:	6105                	addi	sp,sp,32
ffffffffc0201a68:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a6a:	6418                	ld	a4,8(s0)
ffffffffc0201a6c:	e798                	sd	a4,8(a5)
ffffffffc0201a6e:	b7d1                	j	ffffffffc0201a32 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a70:	ec1fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a74:	4605                	li	a2,1
ffffffffc0201a76:	bf99                	j	ffffffffc02019cc <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a78:	843e                	mv	s0,a5
ffffffffc0201a7a:	87b6                	mv	a5,a3
ffffffffc0201a7c:	b745                	j	ffffffffc0201a1c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a7e:	00003697          	auipc	a3,0x3
ffffffffc0201a82:	30268693          	addi	a3,a3,770 # ffffffffc0204d80 <default_pmm_manager+0x70>
ffffffffc0201a86:	00003617          	auipc	a2,0x3
ffffffffc0201a8a:	eda60613          	addi	a2,a2,-294 # ffffffffc0204960 <commands+0x818>
ffffffffc0201a8e:	06300593          	li	a1,99
ffffffffc0201a92:	00003517          	auipc	a0,0x3
ffffffffc0201a96:	30e50513          	addi	a0,a0,782 # ffffffffc0204da0 <default_pmm_manager+0x90>
ffffffffc0201a9a:	9c1fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a9e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a9e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201aa0:	00003517          	auipc	a0,0x3
ffffffffc0201aa4:	31850513          	addi	a0,a0,792 # ffffffffc0204db8 <default_pmm_manager+0xa8>
{
ffffffffc0201aa8:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201aaa:	eeafe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201aae:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ab0:	00003517          	auipc	a0,0x3
ffffffffc0201ab4:	32050513          	addi	a0,a0,800 # ffffffffc0204dd0 <default_pmm_manager+0xc0>
}
ffffffffc0201ab8:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aba:	edafe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201abe <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201abe:	1101                	addi	sp,sp,-32
ffffffffc0201ac0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ac2:	6905                	lui	s2,0x1
{
ffffffffc0201ac4:	e822                	sd	s0,16(sp)
ffffffffc0201ac6:	ec06                	sd	ra,24(sp)
ffffffffc0201ac8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aca:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201ace:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ad0:	04a7f963          	bgeu	a5,a0,ffffffffc0201b22 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ad4:	4561                	li	a0,24
ffffffffc0201ad6:	ed3ff0ef          	jal	ra,ffffffffc02019a8 <slob_alloc.constprop.0>
ffffffffc0201ada:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201adc:	c929                	beqz	a0,ffffffffc0201b2e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ade:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ae2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ae4:	00f95763          	bge	s2,a5,ffffffffc0201af2 <kmalloc+0x34>
ffffffffc0201ae8:	6705                	lui	a4,0x1
ffffffffc0201aea:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201aec:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201aee:	fef74ee3          	blt	a4,a5,ffffffffc0201aea <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201af2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201af4:	e51ff0ef          	jal	ra,ffffffffc0201944 <__slob_get_free_pages.constprop.0>
ffffffffc0201af8:	e488                	sd	a0,8(s1)
ffffffffc0201afa:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201afc:	c525                	beqz	a0,ffffffffc0201b64 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201afe:	100027f3          	csrr	a5,sstatus
ffffffffc0201b02:	8b89                	andi	a5,a5,2
ffffffffc0201b04:	ef8d                	bnez	a5,ffffffffc0201b3e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b06:	0000c797          	auipc	a5,0xc
ffffffffc0201b0a:	99278793          	addi	a5,a5,-1646 # ffffffffc020d498 <bigblocks>
ffffffffc0201b0e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b10:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b12:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201b14:	60e2                	ld	ra,24(sp)
ffffffffc0201b16:	8522                	mv	a0,s0
ffffffffc0201b18:	6442                	ld	s0,16(sp)
ffffffffc0201b1a:	64a2                	ld	s1,8(sp)
ffffffffc0201b1c:	6902                	ld	s2,0(sp)
ffffffffc0201b1e:	6105                	addi	sp,sp,32
ffffffffc0201b20:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b22:	0541                	addi	a0,a0,16
ffffffffc0201b24:	e85ff0ef          	jal	ra,ffffffffc02019a8 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b28:	01050413          	addi	s0,a0,16
ffffffffc0201b2c:	f565                	bnez	a0,ffffffffc0201b14 <kmalloc+0x56>
ffffffffc0201b2e:	4401                	li	s0,0
}
ffffffffc0201b30:	60e2                	ld	ra,24(sp)
ffffffffc0201b32:	8522                	mv	a0,s0
ffffffffc0201b34:	6442                	ld	s0,16(sp)
ffffffffc0201b36:	64a2                	ld	s1,8(sp)
ffffffffc0201b38:	6902                	ld	s2,0(sp)
ffffffffc0201b3a:	6105                	addi	sp,sp,32
ffffffffc0201b3c:	8082                	ret
        intr_disable();
ffffffffc0201b3e:	df3fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b42:	0000c797          	auipc	a5,0xc
ffffffffc0201b46:	95678793          	addi	a5,a5,-1706 # ffffffffc020d498 <bigblocks>
ffffffffc0201b4a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b4c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b4e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b50:	ddbfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b54:	6480                	ld	s0,8(s1)
}
ffffffffc0201b56:	60e2                	ld	ra,24(sp)
ffffffffc0201b58:	64a2                	ld	s1,8(sp)
ffffffffc0201b5a:	8522                	mv	a0,s0
ffffffffc0201b5c:	6442                	ld	s0,16(sp)
ffffffffc0201b5e:	6902                	ld	s2,0(sp)
ffffffffc0201b60:	6105                	addi	sp,sp,32
ffffffffc0201b62:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b64:	45e1                	li	a1,24
ffffffffc0201b66:	8526                	mv	a0,s1
ffffffffc0201b68:	d29ff0ef          	jal	ra,ffffffffc0201890 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b6c:	b765                	j	ffffffffc0201b14 <kmalloc+0x56>

ffffffffc0201b6e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b6e:	c169                	beqz	a0,ffffffffc0201c30 <kfree+0xc2>
{
ffffffffc0201b70:	1101                	addi	sp,sp,-32
ffffffffc0201b72:	e822                	sd	s0,16(sp)
ffffffffc0201b74:	ec06                	sd	ra,24(sp)
ffffffffc0201b76:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b78:	03451793          	slli	a5,a0,0x34
ffffffffc0201b7c:	842a                	mv	s0,a0
ffffffffc0201b7e:	e3d9                	bnez	a5,ffffffffc0201c04 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b80:	100027f3          	csrr	a5,sstatus
ffffffffc0201b84:	8b89                	andi	a5,a5,2
ffffffffc0201b86:	e7d9                	bnez	a5,ffffffffc0201c14 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b88:	0000c797          	auipc	a5,0xc
ffffffffc0201b8c:	9107b783          	ld	a5,-1776(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b90:	4601                	li	a2,0
ffffffffc0201b92:	cbad                	beqz	a5,ffffffffc0201c04 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b94:	0000c697          	auipc	a3,0xc
ffffffffc0201b98:	90468693          	addi	a3,a3,-1788 # ffffffffc020d498 <bigblocks>
ffffffffc0201b9c:	a021                	j	ffffffffc0201ba4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b9e:	01048693          	addi	a3,s1,16
ffffffffc0201ba2:	c3a5                	beqz	a5,ffffffffc0201c02 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201ba4:	6798                	ld	a4,8(a5)
ffffffffc0201ba6:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201ba8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201baa:	fe871ae3          	bne	a4,s0,ffffffffc0201b9e <kfree+0x30>
				*last = bb->next;
ffffffffc0201bae:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bb0:	ee2d                	bnez	a2,ffffffffc0201c2a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bb2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bb6:	4098                	lw	a4,0(s1)
ffffffffc0201bb8:	08f46963          	bltu	s0,a5,ffffffffc0201c4a <kfree+0xdc>
ffffffffc0201bbc:	0000c697          	auipc	a3,0xc
ffffffffc0201bc0:	90c6b683          	ld	a3,-1780(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201bc4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201bc6:	8031                	srli	s0,s0,0xc
ffffffffc0201bc8:	0000c797          	auipc	a5,0xc
ffffffffc0201bcc:	8e87b783          	ld	a5,-1816(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201bd0:	06f47163          	bgeu	s0,a5,ffffffffc0201c32 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bd4:	00004517          	auipc	a0,0x4
ffffffffc0201bd8:	e5453503          	ld	a0,-428(a0) # ffffffffc0205a28 <nbase>
ffffffffc0201bdc:	8c09                	sub	s0,s0,a0
ffffffffc0201bde:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201be0:	0000c517          	auipc	a0,0xc
ffffffffc0201be4:	8d853503          	ld	a0,-1832(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201be8:	4585                	li	a1,1
ffffffffc0201bea:	9522                	add	a0,a0,s0
ffffffffc0201bec:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201bf0:	0ea000ef          	jal	ra,ffffffffc0201cda <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bf4:	6442                	ld	s0,16(sp)
ffffffffc0201bf6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bf8:	8526                	mv	a0,s1
}
ffffffffc0201bfa:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bfc:	45e1                	li	a1,24
}
ffffffffc0201bfe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c00:	b941                	j	ffffffffc0201890 <slob_free>
ffffffffc0201c02:	e20d                	bnez	a2,ffffffffc0201c24 <kfree+0xb6>
ffffffffc0201c04:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c08:	6442                	ld	s0,16(sp)
ffffffffc0201c0a:	60e2                	ld	ra,24(sp)
ffffffffc0201c0c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c0e:	4581                	li	a1,0
}
ffffffffc0201c10:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c12:	b9bd                	j	ffffffffc0201890 <slob_free>
        intr_disable();
ffffffffc0201c14:	d1dfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c18:	0000c797          	auipc	a5,0xc
ffffffffc0201c1c:	8807b783          	ld	a5,-1920(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c20:	4605                	li	a2,1
ffffffffc0201c22:	fbad                	bnez	a5,ffffffffc0201b94 <kfree+0x26>
        intr_enable();
ffffffffc0201c24:	d07fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c28:	bff1                	j	ffffffffc0201c04 <kfree+0x96>
ffffffffc0201c2a:	d01fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c2e:	b751                	j	ffffffffc0201bb2 <kfree+0x44>
ffffffffc0201c30:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c32:	00003617          	auipc	a2,0x3
ffffffffc0201c36:	1e660613          	addi	a2,a2,486 # ffffffffc0204e18 <default_pmm_manager+0x108>
ffffffffc0201c3a:	06900593          	li	a1,105
ffffffffc0201c3e:	00003517          	auipc	a0,0x3
ffffffffc0201c42:	13250513          	addi	a0,a0,306 # ffffffffc0204d70 <default_pmm_manager+0x60>
ffffffffc0201c46:	815fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c4a:	86a2                	mv	a3,s0
ffffffffc0201c4c:	00003617          	auipc	a2,0x3
ffffffffc0201c50:	1a460613          	addi	a2,a2,420 # ffffffffc0204df0 <default_pmm_manager+0xe0>
ffffffffc0201c54:	07700593          	li	a1,119
ffffffffc0201c58:	00003517          	auipc	a0,0x3
ffffffffc0201c5c:	11850513          	addi	a0,a0,280 # ffffffffc0204d70 <default_pmm_manager+0x60>
ffffffffc0201c60:	ffafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c64 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c64:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c66:	00003617          	auipc	a2,0x3
ffffffffc0201c6a:	1b260613          	addi	a2,a2,434 # ffffffffc0204e18 <default_pmm_manager+0x108>
ffffffffc0201c6e:	06900593          	li	a1,105
ffffffffc0201c72:	00003517          	auipc	a0,0x3
ffffffffc0201c76:	0fe50513          	addi	a0,a0,254 # ffffffffc0204d70 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c7a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c7c:	fdefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c80 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c80:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c82:	00003617          	auipc	a2,0x3
ffffffffc0201c86:	1b660613          	addi	a2,a2,438 # ffffffffc0204e38 <default_pmm_manager+0x128>
ffffffffc0201c8a:	07f00593          	li	a1,127
ffffffffc0201c8e:	00003517          	auipc	a0,0x3
ffffffffc0201c92:	0e250513          	addi	a0,a0,226 # ffffffffc0204d70 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c96:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c98:	fc2fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c9c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c9c:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca0:	8b89                	andi	a5,a5,2
ffffffffc0201ca2:	e799                	bnez	a5,ffffffffc0201cb0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ca4:	0000c797          	auipc	a5,0xc
ffffffffc0201ca8:	81c7b783          	ld	a5,-2020(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cac:	6f9c                	ld	a5,24(a5)
ffffffffc0201cae:	8782                	jr	a5
{
ffffffffc0201cb0:	1141                	addi	sp,sp,-16
ffffffffc0201cb2:	e406                	sd	ra,8(sp)
ffffffffc0201cb4:	e022                	sd	s0,0(sp)
ffffffffc0201cb6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201cb8:	c79fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cbc:	0000c797          	auipc	a5,0xc
ffffffffc0201cc0:	8047b783          	ld	a5,-2044(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cc4:	6f9c                	ld	a5,24(a5)
ffffffffc0201cc6:	8522                	mv	a0,s0
ffffffffc0201cc8:	9782                	jalr	a5
ffffffffc0201cca:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ccc:	c5ffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201cd0:	60a2                	ld	ra,8(sp)
ffffffffc0201cd2:	8522                	mv	a0,s0
ffffffffc0201cd4:	6402                	ld	s0,0(sp)
ffffffffc0201cd6:	0141                	addi	sp,sp,16
ffffffffc0201cd8:	8082                	ret

ffffffffc0201cda <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cda:	100027f3          	csrr	a5,sstatus
ffffffffc0201cde:	8b89                	andi	a5,a5,2
ffffffffc0201ce0:	e799                	bnez	a5,ffffffffc0201cee <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ce2:	0000b797          	auipc	a5,0xb
ffffffffc0201ce6:	7de7b783          	ld	a5,2014(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cea:	739c                	ld	a5,32(a5)
ffffffffc0201cec:	8782                	jr	a5
{
ffffffffc0201cee:	1101                	addi	sp,sp,-32
ffffffffc0201cf0:	ec06                	sd	ra,24(sp)
ffffffffc0201cf2:	e822                	sd	s0,16(sp)
ffffffffc0201cf4:	e426                	sd	s1,8(sp)
ffffffffc0201cf6:	842a                	mv	s0,a0
ffffffffc0201cf8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201cfa:	c37fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cfe:	0000b797          	auipc	a5,0xb
ffffffffc0201d02:	7c27b783          	ld	a5,1986(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d06:	739c                	ld	a5,32(a5)
ffffffffc0201d08:	85a6                	mv	a1,s1
ffffffffc0201d0a:	8522                	mv	a0,s0
ffffffffc0201d0c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d0e:	6442                	ld	s0,16(sp)
ffffffffc0201d10:	60e2                	ld	ra,24(sp)
ffffffffc0201d12:	64a2                	ld	s1,8(sp)
ffffffffc0201d14:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d16:	c15fe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201d1a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d1a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d1e:	8b89                	andi	a5,a5,2
ffffffffc0201d20:	e799                	bnez	a5,ffffffffc0201d2e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d22:	0000b797          	auipc	a5,0xb
ffffffffc0201d26:	79e7b783          	ld	a5,1950(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d2a:	779c                	ld	a5,40(a5)
ffffffffc0201d2c:	8782                	jr	a5
{
ffffffffc0201d2e:	1141                	addi	sp,sp,-16
ffffffffc0201d30:	e406                	sd	ra,8(sp)
ffffffffc0201d32:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d34:	bfdfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d38:	0000b797          	auipc	a5,0xb
ffffffffc0201d3c:	7887b783          	ld	a5,1928(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d40:	779c                	ld	a5,40(a5)
ffffffffc0201d42:	9782                	jalr	a5
ffffffffc0201d44:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d46:	be5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d4a:	60a2                	ld	ra,8(sp)
ffffffffc0201d4c:	8522                	mv	a0,s0
ffffffffc0201d4e:	6402                	ld	s0,0(sp)
ffffffffc0201d50:	0141                	addi	sp,sp,16
ffffffffc0201d52:	8082                	ret

ffffffffc0201d54 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d54:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d58:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d5c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d5e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d60:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d62:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d66:	6094                	ld	a3,0(s1)
{
ffffffffc0201d68:	f04a                	sd	s2,32(sp)
ffffffffc0201d6a:	ec4e                	sd	s3,24(sp)
ffffffffc0201d6c:	e852                	sd	s4,16(sp)
ffffffffc0201d6e:	fc06                	sd	ra,56(sp)
ffffffffc0201d70:	f822                	sd	s0,48(sp)
ffffffffc0201d72:	e456                	sd	s5,8(sp)
ffffffffc0201d74:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d76:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d7a:	892e                	mv	s2,a1
ffffffffc0201d7c:	8a32                	mv	s4,a2
ffffffffc0201d7e:	0000b997          	auipc	s3,0xb
ffffffffc0201d82:	73298993          	addi	s3,s3,1842 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d86:	efbd                	bnez	a5,ffffffffc0201e04 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d88:	14060c63          	beqz	a2,ffffffffc0201ee0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d90:	8b89                	andi	a5,a5,2
ffffffffc0201d92:	14079963          	bnez	a5,ffffffffc0201ee4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d96:	0000b797          	auipc	a5,0xb
ffffffffc0201d9a:	72a7b783          	ld	a5,1834(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d9e:	6f9c                	ld	a5,24(a5)
ffffffffc0201da0:	4505                	li	a0,1
ffffffffc0201da2:	9782                	jalr	a5
ffffffffc0201da4:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201da6:	12040d63          	beqz	s0,ffffffffc0201ee0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201daa:	0000bb17          	auipc	s6,0xb
ffffffffc0201dae:	70eb0b13          	addi	s6,s6,1806 # ffffffffc020d4b8 <pages>
ffffffffc0201db2:	000b3503          	ld	a0,0(s6)
ffffffffc0201db6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201dba:	0000b997          	auipc	s3,0xb
ffffffffc0201dbe:	6f698993          	addi	s3,s3,1782 # ffffffffc020d4b0 <npage>
ffffffffc0201dc2:	40a40533          	sub	a0,s0,a0
ffffffffc0201dc6:	8519                	srai	a0,a0,0x6
ffffffffc0201dc8:	9556                	add	a0,a0,s5
ffffffffc0201dca:	0009b703          	ld	a4,0(s3)
ffffffffc0201dce:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201dd2:	4685                	li	a3,1
ffffffffc0201dd4:	c014                	sw	a3,0(s0)
ffffffffc0201dd6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dd8:	0532                	slli	a0,a0,0xc
ffffffffc0201dda:	16e7f763          	bgeu	a5,a4,ffffffffc0201f48 <get_pte+0x1f4>
ffffffffc0201dde:	0000b797          	auipc	a5,0xb
ffffffffc0201de2:	6ea7b783          	ld	a5,1770(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201de6:	6605                	lui	a2,0x1
ffffffffc0201de8:	4581                	li	a1,0
ffffffffc0201dea:	953e                	add	a0,a0,a5
ffffffffc0201dec:	0a4020ef          	jal	ra,ffffffffc0203e90 <memset>
    return page - pages + nbase;
ffffffffc0201df0:	000b3683          	ld	a3,0(s6)
ffffffffc0201df4:	40d406b3          	sub	a3,s0,a3
ffffffffc0201df8:	8699                	srai	a3,a3,0x6
ffffffffc0201dfa:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201dfc:	06aa                	slli	a3,a3,0xa
ffffffffc0201dfe:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e02:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e04:	77fd                	lui	a5,0xfffff
ffffffffc0201e06:	068a                	slli	a3,a3,0x2
ffffffffc0201e08:	0009b703          	ld	a4,0(s3)
ffffffffc0201e0c:	8efd                	and	a3,a3,a5
ffffffffc0201e0e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e12:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f30 <get_pte+0x1dc>
ffffffffc0201e16:	0000ba97          	auipc	s5,0xb
ffffffffc0201e1a:	6b2a8a93          	addi	s5,s5,1714 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e1e:	000ab403          	ld	s0,0(s5)
ffffffffc0201e22:	01595793          	srli	a5,s2,0x15
ffffffffc0201e26:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e2a:	96a2                	add	a3,a3,s0
ffffffffc0201e2c:	00379413          	slli	s0,a5,0x3
ffffffffc0201e30:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201e32:	6014                	ld	a3,0(s0)
ffffffffc0201e34:	0016f793          	andi	a5,a3,1
ffffffffc0201e38:	ebad                	bnez	a5,ffffffffc0201eaa <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e3a:	0a0a0363          	beqz	s4,ffffffffc0201ee0 <get_pte+0x18c>
ffffffffc0201e3e:	100027f3          	csrr	a5,sstatus
ffffffffc0201e42:	8b89                	andi	a5,a5,2
ffffffffc0201e44:	efcd                	bnez	a5,ffffffffc0201efe <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e46:	0000b797          	auipc	a5,0xb
ffffffffc0201e4a:	67a7b783          	ld	a5,1658(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e4e:	6f9c                	ld	a5,24(a5)
ffffffffc0201e50:	4505                	li	a0,1
ffffffffc0201e52:	9782                	jalr	a5
ffffffffc0201e54:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e56:	c4c9                	beqz	s1,ffffffffc0201ee0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e58:	0000bb17          	auipc	s6,0xb
ffffffffc0201e5c:	660b0b13          	addi	s6,s6,1632 # ffffffffc020d4b8 <pages>
ffffffffc0201e60:	000b3503          	ld	a0,0(s6)
ffffffffc0201e64:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e68:	0009b703          	ld	a4,0(s3)
ffffffffc0201e6c:	40a48533          	sub	a0,s1,a0
ffffffffc0201e70:	8519                	srai	a0,a0,0x6
ffffffffc0201e72:	9552                	add	a0,a0,s4
ffffffffc0201e74:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e78:	4685                	li	a3,1
ffffffffc0201e7a:	c094                	sw	a3,0(s1)
ffffffffc0201e7c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e7e:	0532                	slli	a0,a0,0xc
ffffffffc0201e80:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f62 <get_pte+0x20e>
ffffffffc0201e84:	000ab783          	ld	a5,0(s5)
ffffffffc0201e88:	6605                	lui	a2,0x1
ffffffffc0201e8a:	4581                	li	a1,0
ffffffffc0201e8c:	953e                	add	a0,a0,a5
ffffffffc0201e8e:	002020ef          	jal	ra,ffffffffc0203e90 <memset>
    return page - pages + nbase;
ffffffffc0201e92:	000b3683          	ld	a3,0(s6)
ffffffffc0201e96:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e9a:	8699                	srai	a3,a3,0x6
ffffffffc0201e9c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e9e:	06aa                	slli	a3,a3,0xa
ffffffffc0201ea0:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ea4:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ea6:	0009b703          	ld	a4,0(s3)
ffffffffc0201eaa:	068a                	slli	a3,a3,0x2
ffffffffc0201eac:	757d                	lui	a0,0xfffff
ffffffffc0201eae:	8ee9                	and	a3,a3,a0
ffffffffc0201eb0:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201eb4:	06e7f263          	bgeu	a5,a4,ffffffffc0201f18 <get_pte+0x1c4>
ffffffffc0201eb8:	000ab503          	ld	a0,0(s5)
ffffffffc0201ebc:	00c95913          	srli	s2,s2,0xc
ffffffffc0201ec0:	1ff97913          	andi	s2,s2,511
ffffffffc0201ec4:	96aa                	add	a3,a3,a0
ffffffffc0201ec6:	00391513          	slli	a0,s2,0x3
ffffffffc0201eca:	9536                	add	a0,a0,a3
}
ffffffffc0201ecc:	70e2                	ld	ra,56(sp)
ffffffffc0201ece:	7442                	ld	s0,48(sp)
ffffffffc0201ed0:	74a2                	ld	s1,40(sp)
ffffffffc0201ed2:	7902                	ld	s2,32(sp)
ffffffffc0201ed4:	69e2                	ld	s3,24(sp)
ffffffffc0201ed6:	6a42                	ld	s4,16(sp)
ffffffffc0201ed8:	6aa2                	ld	s5,8(sp)
ffffffffc0201eda:	6b02                	ld	s6,0(sp)
ffffffffc0201edc:	6121                	addi	sp,sp,64
ffffffffc0201ede:	8082                	ret
            return NULL;
ffffffffc0201ee0:	4501                	li	a0,0
ffffffffc0201ee2:	b7ed                	j	ffffffffc0201ecc <get_pte+0x178>
        intr_disable();
ffffffffc0201ee4:	a4dfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ee8:	0000b797          	auipc	a5,0xb
ffffffffc0201eec:	5d87b783          	ld	a5,1496(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ef0:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef2:	4505                	li	a0,1
ffffffffc0201ef4:	9782                	jalr	a5
ffffffffc0201ef6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ef8:	a33fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201efc:	b56d                	j	ffffffffc0201da6 <get_pte+0x52>
        intr_disable();
ffffffffc0201efe:	a33fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201f02:	0000b797          	auipc	a5,0xb
ffffffffc0201f06:	5be7b783          	ld	a5,1470(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201f0a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f0c:	4505                	li	a0,1
ffffffffc0201f0e:	9782                	jalr	a5
ffffffffc0201f10:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201f12:	a19fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f16:	b781                	j	ffffffffc0201e56 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f18:	00003617          	auipc	a2,0x3
ffffffffc0201f1c:	e3060613          	addi	a2,a2,-464 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0201f20:	0fb00593          	li	a1,251
ffffffffc0201f24:	00003517          	auipc	a0,0x3
ffffffffc0201f28:	f3c50513          	addi	a0,a0,-196 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0201f2c:	d2efe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f30:	00003617          	auipc	a2,0x3
ffffffffc0201f34:	e1860613          	addi	a2,a2,-488 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0201f38:	0ee00593          	li	a1,238
ffffffffc0201f3c:	00003517          	auipc	a0,0x3
ffffffffc0201f40:	f2450513          	addi	a0,a0,-220 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0201f44:	d16fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f48:	86aa                	mv	a3,a0
ffffffffc0201f4a:	00003617          	auipc	a2,0x3
ffffffffc0201f4e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0201f52:	0eb00593          	li	a1,235
ffffffffc0201f56:	00003517          	auipc	a0,0x3
ffffffffc0201f5a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0201f5e:	cfcfe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f62:	86aa                	mv	a3,a0
ffffffffc0201f64:	00003617          	auipc	a2,0x3
ffffffffc0201f68:	de460613          	addi	a2,a2,-540 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0201f6c:	0f800593          	li	a1,248
ffffffffc0201f70:	00003517          	auipc	a0,0x3
ffffffffc0201f74:	ef050513          	addi	a0,a0,-272 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0201f78:	ce2fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f7c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f7c:	1141                	addi	sp,sp,-16
ffffffffc0201f7e:	e022                	sd	s0,0(sp)
ffffffffc0201f80:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f82:	4601                	li	a2,0
{
ffffffffc0201f84:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f86:	dcfff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f8a:	c011                	beqz	s0,ffffffffc0201f8e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f8c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f8e:	c511                	beqz	a0,ffffffffc0201f9a <get_page+0x1e>
ffffffffc0201f90:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f92:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f94:	0017f713          	andi	a4,a5,1
ffffffffc0201f98:	e709                	bnez	a4,ffffffffc0201fa2 <get_page+0x26>
}
ffffffffc0201f9a:	60a2                	ld	ra,8(sp)
ffffffffc0201f9c:	6402                	ld	s0,0(sp)
ffffffffc0201f9e:	0141                	addi	sp,sp,16
ffffffffc0201fa0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fa2:	078a                	slli	a5,a5,0x2
ffffffffc0201fa4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fa6:	0000b717          	auipc	a4,0xb
ffffffffc0201faa:	50a73703          	ld	a4,1290(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201fae:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fcc <get_page+0x50>
ffffffffc0201fb2:	60a2                	ld	ra,8(sp)
ffffffffc0201fb4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fb6:	fff80537          	lui	a0,0xfff80
ffffffffc0201fba:	97aa                	add	a5,a5,a0
ffffffffc0201fbc:	079a                	slli	a5,a5,0x6
ffffffffc0201fbe:	0000b517          	auipc	a0,0xb
ffffffffc0201fc2:	4fa53503          	ld	a0,1274(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fc6:	953e                	add	a0,a0,a5
ffffffffc0201fc8:	0141                	addi	sp,sp,16
ffffffffc0201fca:	8082                	ret
ffffffffc0201fcc:	c99ff0ef          	jal	ra,ffffffffc0201c64 <pa2page.part.0>

ffffffffc0201fd0 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fd0:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fd2:	4601                	li	a2,0
{
ffffffffc0201fd4:	ec26                	sd	s1,24(sp)
ffffffffc0201fd6:	f406                	sd	ra,40(sp)
ffffffffc0201fd8:	f022                	sd	s0,32(sp)
ffffffffc0201fda:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fdc:	d79ff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
    if (ptep != NULL)
ffffffffc0201fe0:	c511                	beqz	a0,ffffffffc0201fec <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201fe2:	611c                	ld	a5,0(a0)
ffffffffc0201fe4:	842a                	mv	s0,a0
ffffffffc0201fe6:	0017f713          	andi	a4,a5,1
ffffffffc0201fea:	e711                	bnez	a4,ffffffffc0201ff6 <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fec:	70a2                	ld	ra,40(sp)
ffffffffc0201fee:	7402                	ld	s0,32(sp)
ffffffffc0201ff0:	64e2                	ld	s1,24(sp)
ffffffffc0201ff2:	6145                	addi	sp,sp,48
ffffffffc0201ff4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ff6:	078a                	slli	a5,a5,0x2
ffffffffc0201ff8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ffa:	0000b717          	auipc	a4,0xb
ffffffffc0201ffe:	4b673703          	ld	a4,1206(a4) # ffffffffc020d4b0 <npage>
ffffffffc0202002:	06e7f363          	bgeu	a5,a4,ffffffffc0202068 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202006:	fff80537          	lui	a0,0xfff80
ffffffffc020200a:	97aa                	add	a5,a5,a0
ffffffffc020200c:	079a                	slli	a5,a5,0x6
ffffffffc020200e:	0000b517          	auipc	a0,0xb
ffffffffc0202012:	4aa53503          	ld	a0,1194(a0) # ffffffffc020d4b8 <pages>
ffffffffc0202016:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202018:	411c                	lw	a5,0(a0)
ffffffffc020201a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020201e:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202020:	cb11                	beqz	a4,ffffffffc0202034 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202022:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202026:	12048073          	sfence.vma	s1
}
ffffffffc020202a:	70a2                	ld	ra,40(sp)
ffffffffc020202c:	7402                	ld	s0,32(sp)
ffffffffc020202e:	64e2                	ld	s1,24(sp)
ffffffffc0202030:	6145                	addi	sp,sp,48
ffffffffc0202032:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202034:	100027f3          	csrr	a5,sstatus
ffffffffc0202038:	8b89                	andi	a5,a5,2
ffffffffc020203a:	eb89                	bnez	a5,ffffffffc020204c <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc020203c:	0000b797          	auipc	a5,0xb
ffffffffc0202040:	4847b783          	ld	a5,1156(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202044:	739c                	ld	a5,32(a5)
ffffffffc0202046:	4585                	li	a1,1
ffffffffc0202048:	9782                	jalr	a5
    if (flag) {
ffffffffc020204a:	bfe1                	j	ffffffffc0202022 <page_remove+0x52>
        intr_disable();
ffffffffc020204c:	e42a                	sd	a0,8(sp)
ffffffffc020204e:	8e3fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202052:	0000b797          	auipc	a5,0xb
ffffffffc0202056:	46e7b783          	ld	a5,1134(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020205a:	739c                	ld	a5,32(a5)
ffffffffc020205c:	6522                	ld	a0,8(sp)
ffffffffc020205e:	4585                	li	a1,1
ffffffffc0202060:	9782                	jalr	a5
        intr_enable();
ffffffffc0202062:	8c9fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202066:	bf75                	j	ffffffffc0202022 <page_remove+0x52>
ffffffffc0202068:	bfdff0ef          	jal	ra,ffffffffc0201c64 <pa2page.part.0>

ffffffffc020206c <page_insert>:
{
ffffffffc020206c:	7139                	addi	sp,sp,-64
ffffffffc020206e:	e852                	sd	s4,16(sp)
ffffffffc0202070:	8a32                	mv	s4,a2
ffffffffc0202072:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202074:	4605                	li	a2,1
{
ffffffffc0202076:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202078:	85d2                	mv	a1,s4
{
ffffffffc020207a:	f426                	sd	s1,40(sp)
ffffffffc020207c:	fc06                	sd	ra,56(sp)
ffffffffc020207e:	f04a                	sd	s2,32(sp)
ffffffffc0202080:	ec4e                	sd	s3,24(sp)
ffffffffc0202082:	e456                	sd	s5,8(sp)
ffffffffc0202084:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202086:	ccfff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
    if (ptep == NULL)
ffffffffc020208a:	c961                	beqz	a0,ffffffffc020215a <page_insert+0xee>
    page->ref += 1;
ffffffffc020208c:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020208e:	611c                	ld	a5,0(a0)
ffffffffc0202090:	89aa                	mv	s3,a0
ffffffffc0202092:	0016871b          	addiw	a4,a3,1
ffffffffc0202096:	c018                	sw	a4,0(s0)
ffffffffc0202098:	0017f713          	andi	a4,a5,1
ffffffffc020209c:	ef05                	bnez	a4,ffffffffc02020d4 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020209e:	0000b717          	auipc	a4,0xb
ffffffffc02020a2:	41a73703          	ld	a4,1050(a4) # ffffffffc020d4b8 <pages>
ffffffffc02020a6:	8c19                	sub	s0,s0,a4
ffffffffc02020a8:	000807b7          	lui	a5,0x80
ffffffffc02020ac:	8419                	srai	s0,s0,0x6
ffffffffc02020ae:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020b0:	042a                	slli	s0,s0,0xa
ffffffffc02020b2:	8cc1                	or	s1,s1,s0
ffffffffc02020b4:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02020b8:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020bc:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020c0:	4501                	li	a0,0
}
ffffffffc02020c2:	70e2                	ld	ra,56(sp)
ffffffffc02020c4:	7442                	ld	s0,48(sp)
ffffffffc02020c6:	74a2                	ld	s1,40(sp)
ffffffffc02020c8:	7902                	ld	s2,32(sp)
ffffffffc02020ca:	69e2                	ld	s3,24(sp)
ffffffffc02020cc:	6a42                	ld	s4,16(sp)
ffffffffc02020ce:	6aa2                	ld	s5,8(sp)
ffffffffc02020d0:	6121                	addi	sp,sp,64
ffffffffc02020d2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020d4:	078a                	slli	a5,a5,0x2
ffffffffc02020d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020d8:	0000b717          	auipc	a4,0xb
ffffffffc02020dc:	3d873703          	ld	a4,984(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020e0:	06e7ff63          	bgeu	a5,a4,ffffffffc020215e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020e4:	0000ba97          	auipc	s5,0xb
ffffffffc02020e8:	3d4a8a93          	addi	s5,s5,980 # ffffffffc020d4b8 <pages>
ffffffffc02020ec:	000ab703          	ld	a4,0(s5)
ffffffffc02020f0:	fff80937          	lui	s2,0xfff80
ffffffffc02020f4:	993e                	add	s2,s2,a5
ffffffffc02020f6:	091a                	slli	s2,s2,0x6
ffffffffc02020f8:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020fa:	01240c63          	beq	s0,s2,ffffffffc0202112 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02020fe:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc0202102:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202106:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020210a:	c691                	beqz	a3,ffffffffc0202116 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020210c:	120a0073          	sfence.vma	s4
}
ffffffffc0202110:	bf59                	j	ffffffffc02020a6 <page_insert+0x3a>
ffffffffc0202112:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202114:	bf49                	j	ffffffffc02020a6 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202116:	100027f3          	csrr	a5,sstatus
ffffffffc020211a:	8b89                	andi	a5,a5,2
ffffffffc020211c:	ef91                	bnez	a5,ffffffffc0202138 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020211e:	0000b797          	auipc	a5,0xb
ffffffffc0202122:	3a27b783          	ld	a5,930(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202126:	739c                	ld	a5,32(a5)
ffffffffc0202128:	4585                	li	a1,1
ffffffffc020212a:	854a                	mv	a0,s2
ffffffffc020212c:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020212e:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202132:	120a0073          	sfence.vma	s4
ffffffffc0202136:	bf85                	j	ffffffffc02020a6 <page_insert+0x3a>
        intr_disable();
ffffffffc0202138:	ff8fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020213c:	0000b797          	auipc	a5,0xb
ffffffffc0202140:	3847b783          	ld	a5,900(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202144:	739c                	ld	a5,32(a5)
ffffffffc0202146:	4585                	li	a1,1
ffffffffc0202148:	854a                	mv	a0,s2
ffffffffc020214a:	9782                	jalr	a5
        intr_enable();
ffffffffc020214c:	fdefe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202150:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202154:	120a0073          	sfence.vma	s4
ffffffffc0202158:	b7b9                	j	ffffffffc02020a6 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020215a:	5571                	li	a0,-4
ffffffffc020215c:	b79d                	j	ffffffffc02020c2 <page_insert+0x56>
ffffffffc020215e:	b07ff0ef          	jal	ra,ffffffffc0201c64 <pa2page.part.0>

ffffffffc0202162 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202162:	00003797          	auipc	a5,0x3
ffffffffc0202166:	bae78793          	addi	a5,a5,-1106 # ffffffffc0204d10 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020216a:	638c                	ld	a1,0(a5)
{
ffffffffc020216c:	7159                	addi	sp,sp,-112
ffffffffc020216e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202170:	00003517          	auipc	a0,0x3
ffffffffc0202174:	d0050513          	addi	a0,a0,-768 # ffffffffc0204e70 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc0202178:	0000bb17          	auipc	s6,0xb
ffffffffc020217c:	348b0b13          	addi	s6,s6,840 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202180:	f486                	sd	ra,104(sp)
ffffffffc0202182:	e8ca                	sd	s2,80(sp)
ffffffffc0202184:	e4ce                	sd	s3,72(sp)
ffffffffc0202186:	f0a2                	sd	s0,96(sp)
ffffffffc0202188:	eca6                	sd	s1,88(sp)
ffffffffc020218a:	e0d2                	sd	s4,64(sp)
ffffffffc020218c:	fc56                	sd	s5,56(sp)
ffffffffc020218e:	f45e                	sd	s7,40(sp)
ffffffffc0202190:	f062                	sd	s8,32(sp)
ffffffffc0202192:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202194:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202198:	ffdfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020219c:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021a0:	0000b997          	auipc	s3,0xb
ffffffffc02021a4:	32898993          	addi	s3,s3,808 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02021a8:	679c                	ld	a5,8(a5)
ffffffffc02021aa:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021ac:	57f5                	li	a5,-3
ffffffffc02021ae:	07fa                	slli	a5,a5,0x1e
ffffffffc02021b0:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021b4:	f62fe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc02021b8:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021ba:	f66fe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021be:	200505e3          	beqz	a0,ffffffffc0202bc8 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021c2:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021c4:	00003517          	auipc	a0,0x3
ffffffffc02021c8:	ce450513          	addi	a0,a0,-796 # ffffffffc0204ea8 <default_pmm_manager+0x198>
ffffffffc02021cc:	fc9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021d0:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021d4:	fff40693          	addi	a3,s0,-1
ffffffffc02021d8:	864a                	mv	a2,s2
ffffffffc02021da:	85a6                	mv	a1,s1
ffffffffc02021dc:	00003517          	auipc	a0,0x3
ffffffffc02021e0:	ce450513          	addi	a0,a0,-796 # ffffffffc0204ec0 <default_pmm_manager+0x1b0>
ffffffffc02021e4:	fb1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02021e8:	c8000737          	lui	a4,0xc8000
ffffffffc02021ec:	87a2                	mv	a5,s0
ffffffffc02021ee:	54876163          	bltu	a4,s0,ffffffffc0202730 <pmm_init+0x5ce>
ffffffffc02021f2:	757d                	lui	a0,0xfffff
ffffffffc02021f4:	0000c617          	auipc	a2,0xc
ffffffffc02021f8:	2f760613          	addi	a2,a2,759 # ffffffffc020e4eb <end+0xfff>
ffffffffc02021fc:	8e69                	and	a2,a2,a0
ffffffffc02021fe:	0000b497          	auipc	s1,0xb
ffffffffc0202202:	2b248493          	addi	s1,s1,690 # ffffffffc020d4b0 <npage>
ffffffffc0202206:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020220a:	0000bb97          	auipc	s7,0xb
ffffffffc020220e:	2aeb8b93          	addi	s7,s7,686 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202212:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202214:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202218:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020221c:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020221e:	02f50863          	beq	a0,a5,ffffffffc020224e <pmm_init+0xec>
ffffffffc0202222:	4781                	li	a5,0
ffffffffc0202224:	4585                	li	a1,1
ffffffffc0202226:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020222a:	00679513          	slli	a0,a5,0x6
ffffffffc020222e:	9532                	add	a0,a0,a2
ffffffffc0202230:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc0202234:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202238:	6088                	ld	a0,0(s1)
ffffffffc020223a:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020223c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202240:	00d50733          	add	a4,a0,a3
ffffffffc0202244:	fee7e3e3          	bltu	a5,a4,ffffffffc020222a <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202248:	071a                	slli	a4,a4,0x6
ffffffffc020224a:	00e606b3          	add	a3,a2,a4
ffffffffc020224e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202252:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d4a <pmm_init+0xbe8>
ffffffffc0202256:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020225a:	77fd                	lui	a5,0xfffff
ffffffffc020225c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020225e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202260:	5086eb63          	bltu	a3,s0,ffffffffc0202776 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202264:	00003517          	auipc	a0,0x3
ffffffffc0202268:	c8450513          	addi	a0,a0,-892 # ffffffffc0204ee8 <default_pmm_manager+0x1d8>
ffffffffc020226c:	f29fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202270:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202274:	0000b917          	auipc	s2,0xb
ffffffffc0202278:	23490913          	addi	s2,s2,564 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020227c:	7b9c                	ld	a5,48(a5)
ffffffffc020227e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202280:	00003517          	auipc	a0,0x3
ffffffffc0202284:	c8050513          	addi	a0,a0,-896 # ffffffffc0204f00 <default_pmm_manager+0x1f0>
ffffffffc0202288:	f0dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020228c:	00006697          	auipc	a3,0x6
ffffffffc0202290:	d7468693          	addi	a3,a3,-652 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202294:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202298:	c02007b7          	lui	a5,0xc0200
ffffffffc020229c:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d32 <pmm_init+0xbd0>
ffffffffc02022a0:	0009b783          	ld	a5,0(s3)
ffffffffc02022a4:	8e9d                	sub	a3,a3,a5
ffffffffc02022a6:	0000b797          	auipc	a5,0xb
ffffffffc02022aa:	1ed7bd23          	sd	a3,506(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022ae:	100027f3          	csrr	a5,sstatus
ffffffffc02022b2:	8b89                	andi	a5,a5,2
ffffffffc02022b4:	4a079763          	bnez	a5,ffffffffc0202762 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022b8:	000b3783          	ld	a5,0(s6)
ffffffffc02022bc:	779c                	ld	a5,40(a5)
ffffffffc02022be:	9782                	jalr	a5
ffffffffc02022c0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022c2:	6098                	ld	a4,0(s1)
ffffffffc02022c4:	c80007b7          	lui	a5,0xc8000
ffffffffc02022c8:	83b1                	srli	a5,a5,0xc
ffffffffc02022ca:	66e7e363          	bltu	a5,a4,ffffffffc0202930 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022ce:	00093503          	ld	a0,0(s2)
ffffffffc02022d2:	62050f63          	beqz	a0,ffffffffc0202910 <pmm_init+0x7ae>
ffffffffc02022d6:	03451793          	slli	a5,a0,0x34
ffffffffc02022da:	62079b63          	bnez	a5,ffffffffc0202910 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022de:	4601                	li	a2,0
ffffffffc02022e0:	4581                	li	a1,0
ffffffffc02022e2:	c9bff0ef          	jal	ra,ffffffffc0201f7c <get_page>
ffffffffc02022e6:	60051563          	bnez	a0,ffffffffc02028f0 <pmm_init+0x78e>
ffffffffc02022ea:	100027f3          	csrr	a5,sstatus
ffffffffc02022ee:	8b89                	andi	a5,a5,2
ffffffffc02022f0:	44079e63          	bnez	a5,ffffffffc020274c <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022f4:	000b3783          	ld	a5,0(s6)
ffffffffc02022f8:	4505                	li	a0,1
ffffffffc02022fa:	6f9c                	ld	a5,24(a5)
ffffffffc02022fc:	9782                	jalr	a5
ffffffffc02022fe:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202300:	00093503          	ld	a0,0(s2)
ffffffffc0202304:	4681                	li	a3,0
ffffffffc0202306:	4601                	li	a2,0
ffffffffc0202308:	85d2                	mv	a1,s4
ffffffffc020230a:	d63ff0ef          	jal	ra,ffffffffc020206c <page_insert>
ffffffffc020230e:	26051ae3          	bnez	a0,ffffffffc0202d82 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202312:	00093503          	ld	a0,0(s2)
ffffffffc0202316:	4601                	li	a2,0
ffffffffc0202318:	4581                	li	a1,0
ffffffffc020231a:	a3bff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
ffffffffc020231e:	240502e3          	beqz	a0,ffffffffc0202d62 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202322:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202324:	0017f713          	andi	a4,a5,1
ffffffffc0202328:	5a070263          	beqz	a4,ffffffffc02028cc <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020232c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020232e:	078a                	slli	a5,a5,0x2
ffffffffc0202330:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202332:	58e7fb63          	bgeu	a5,a4,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202336:	000bb683          	ld	a3,0(s7)
ffffffffc020233a:	fff80637          	lui	a2,0xfff80
ffffffffc020233e:	97b2                	add	a5,a5,a2
ffffffffc0202340:	079a                	slli	a5,a5,0x6
ffffffffc0202342:	97b6                	add	a5,a5,a3
ffffffffc0202344:	14fa17e3          	bne	s4,a5,ffffffffc0202c92 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202348:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc020234c:	4785                	li	a5,1
ffffffffc020234e:	12f692e3          	bne	a3,a5,ffffffffc0202c72 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202352:	00093503          	ld	a0,0(s2)
ffffffffc0202356:	77fd                	lui	a5,0xfffff
ffffffffc0202358:	6114                	ld	a3,0(a0)
ffffffffc020235a:	068a                	slli	a3,a3,0x2
ffffffffc020235c:	8efd                	and	a3,a3,a5
ffffffffc020235e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202362:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c5a <pmm_init+0xaf8>
ffffffffc0202366:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020236a:	96e2                	add	a3,a3,s8
ffffffffc020236c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202370:	0a8a                	slli	s5,s5,0x2
ffffffffc0202372:	00fafab3          	and	s5,s5,a5
ffffffffc0202376:	00cad793          	srli	a5,s5,0xc
ffffffffc020237a:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c40 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020237e:	4601                	li	a2,0
ffffffffc0202380:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202382:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202384:	9d1ff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202388:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020238a:	55551363          	bne	a0,s5,ffffffffc02028d0 <pmm_init+0x76e>
ffffffffc020238e:	100027f3          	csrr	a5,sstatus
ffffffffc0202392:	8b89                	andi	a5,a5,2
ffffffffc0202394:	3a079163          	bnez	a5,ffffffffc0202736 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202398:	000b3783          	ld	a5,0(s6)
ffffffffc020239c:	4505                	li	a0,1
ffffffffc020239e:	6f9c                	ld	a5,24(a5)
ffffffffc02023a0:	9782                	jalr	a5
ffffffffc02023a2:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02023a4:	00093503          	ld	a0,0(s2)
ffffffffc02023a8:	46d1                	li	a3,20
ffffffffc02023aa:	6605                	lui	a2,0x1
ffffffffc02023ac:	85e2                	mv	a1,s8
ffffffffc02023ae:	cbfff0ef          	jal	ra,ffffffffc020206c <page_insert>
ffffffffc02023b2:	060517e3          	bnez	a0,ffffffffc0202c20 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023b6:	00093503          	ld	a0,0(s2)
ffffffffc02023ba:	4601                	li	a2,0
ffffffffc02023bc:	6585                	lui	a1,0x1
ffffffffc02023be:	997ff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
ffffffffc02023c2:	02050fe3          	beqz	a0,ffffffffc0202c00 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023c6:	611c                	ld	a5,0(a0)
ffffffffc02023c8:	0107f713          	andi	a4,a5,16
ffffffffc02023cc:	7c070e63          	beqz	a4,ffffffffc0202ba8 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023d0:	8b91                	andi	a5,a5,4
ffffffffc02023d2:	7a078b63          	beqz	a5,ffffffffc0202b88 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023d6:	00093503          	ld	a0,0(s2)
ffffffffc02023da:	611c                	ld	a5,0(a0)
ffffffffc02023dc:	8bc1                	andi	a5,a5,16
ffffffffc02023de:	78078563          	beqz	a5,ffffffffc0202b68 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023e2:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023e6:	4785                	li	a5,1
ffffffffc02023e8:	76f71063          	bne	a4,a5,ffffffffc0202b48 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023ec:	4681                	li	a3,0
ffffffffc02023ee:	6605                	lui	a2,0x1
ffffffffc02023f0:	85d2                	mv	a1,s4
ffffffffc02023f2:	c7bff0ef          	jal	ra,ffffffffc020206c <page_insert>
ffffffffc02023f6:	72051963          	bnez	a0,ffffffffc0202b28 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023fa:	000a2703          	lw	a4,0(s4)
ffffffffc02023fe:	4789                	li	a5,2
ffffffffc0202400:	70f71463          	bne	a4,a5,ffffffffc0202b08 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202404:	000c2783          	lw	a5,0(s8)
ffffffffc0202408:	6e079063          	bnez	a5,ffffffffc0202ae8 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020240c:	00093503          	ld	a0,0(s2)
ffffffffc0202410:	4601                	li	a2,0
ffffffffc0202412:	6585                	lui	a1,0x1
ffffffffc0202414:	941ff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
ffffffffc0202418:	6a050863          	beqz	a0,ffffffffc0202ac8 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc020241c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020241e:	00177793          	andi	a5,a4,1
ffffffffc0202422:	4a078563          	beqz	a5,ffffffffc02028cc <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202426:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202428:	00271793          	slli	a5,a4,0x2
ffffffffc020242c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020242e:	48d7fd63          	bgeu	a5,a3,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202432:	000bb683          	ld	a3,0(s7)
ffffffffc0202436:	fff80ab7          	lui	s5,0xfff80
ffffffffc020243a:	97d6                	add	a5,a5,s5
ffffffffc020243c:	079a                	slli	a5,a5,0x6
ffffffffc020243e:	97b6                	add	a5,a5,a3
ffffffffc0202440:	66fa1463          	bne	s4,a5,ffffffffc0202aa8 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202444:	8b41                	andi	a4,a4,16
ffffffffc0202446:	64071163          	bnez	a4,ffffffffc0202a88 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020244a:	00093503          	ld	a0,0(s2)
ffffffffc020244e:	4581                	li	a1,0
ffffffffc0202450:	b81ff0ef          	jal	ra,ffffffffc0201fd0 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202454:	000a2c83          	lw	s9,0(s4)
ffffffffc0202458:	4785                	li	a5,1
ffffffffc020245a:	60fc9763          	bne	s9,a5,ffffffffc0202a68 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc020245e:	000c2783          	lw	a5,0(s8)
ffffffffc0202462:	5e079363          	bnez	a5,ffffffffc0202a48 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202466:	00093503          	ld	a0,0(s2)
ffffffffc020246a:	6585                	lui	a1,0x1
ffffffffc020246c:	b65ff0ef          	jal	ra,ffffffffc0201fd0 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202470:	000a2783          	lw	a5,0(s4)
ffffffffc0202474:	52079a63          	bnez	a5,ffffffffc02029a8 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202478:	000c2783          	lw	a5,0(s8)
ffffffffc020247c:	50079663          	bnez	a5,ffffffffc0202988 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202480:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202484:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202486:	000a3683          	ld	a3,0(s4)
ffffffffc020248a:	068a                	slli	a3,a3,0x2
ffffffffc020248c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020248e:	42b6fd63          	bgeu	a3,a1,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202492:	000bb503          	ld	a0,0(s7)
ffffffffc0202496:	96d6                	add	a3,a3,s5
ffffffffc0202498:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020249a:	00d507b3          	add	a5,a0,a3
ffffffffc020249e:	439c                	lw	a5,0(a5)
ffffffffc02024a0:	4d979463          	bne	a5,s9,ffffffffc0202968 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02024a4:	8699                	srai	a3,a3,0x6
ffffffffc02024a6:	00080637          	lui	a2,0x80
ffffffffc02024aa:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02024ac:	00c69713          	slli	a4,a3,0xc
ffffffffc02024b0:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02024b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024b4:	48b77e63          	bgeu	a4,a1,ffffffffc0202950 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024b8:	0009b703          	ld	a4,0(s3)
ffffffffc02024bc:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024be:	629c                	ld	a5,0(a3)
ffffffffc02024c0:	078a                	slli	a5,a5,0x2
ffffffffc02024c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c4:	40b7f263          	bgeu	a5,a1,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024c8:	8f91                	sub	a5,a5,a2
ffffffffc02024ca:	079a                	slli	a5,a5,0x6
ffffffffc02024cc:	953e                	add	a0,a0,a5
ffffffffc02024ce:	100027f3          	csrr	a5,sstatus
ffffffffc02024d2:	8b89                	andi	a5,a5,2
ffffffffc02024d4:	30079963          	bnez	a5,ffffffffc02027e6 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024d8:	000b3783          	ld	a5,0(s6)
ffffffffc02024dc:	4585                	li	a1,1
ffffffffc02024de:	739c                	ld	a5,32(a5)
ffffffffc02024e0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024e2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024e6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024e8:	078a                	slli	a5,a5,0x2
ffffffffc02024ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024ec:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f0:	000bb503          	ld	a0,0(s7)
ffffffffc02024f4:	fff80737          	lui	a4,0xfff80
ffffffffc02024f8:	97ba                	add	a5,a5,a4
ffffffffc02024fa:	079a                	slli	a5,a5,0x6
ffffffffc02024fc:	953e                	add	a0,a0,a5
ffffffffc02024fe:	100027f3          	csrr	a5,sstatus
ffffffffc0202502:	8b89                	andi	a5,a5,2
ffffffffc0202504:	2c079563          	bnez	a5,ffffffffc02027ce <pmm_init+0x66c>
ffffffffc0202508:	000b3783          	ld	a5,0(s6)
ffffffffc020250c:	4585                	li	a1,1
ffffffffc020250e:	739c                	ld	a5,32(a5)
ffffffffc0202510:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202512:	00093783          	ld	a5,0(s2)
ffffffffc0202516:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc020251a:	12000073          	sfence.vma
ffffffffc020251e:	100027f3          	csrr	a5,sstatus
ffffffffc0202522:	8b89                	andi	a5,a5,2
ffffffffc0202524:	28079b63          	bnez	a5,ffffffffc02027ba <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202528:	000b3783          	ld	a5,0(s6)
ffffffffc020252c:	779c                	ld	a5,40(a5)
ffffffffc020252e:	9782                	jalr	a5
ffffffffc0202530:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202532:	4b441b63          	bne	s0,s4,ffffffffc02029e8 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202536:	00003517          	auipc	a0,0x3
ffffffffc020253a:	cf250513          	addi	a0,a0,-782 # ffffffffc0205228 <default_pmm_manager+0x518>
ffffffffc020253e:	c57fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202542:	100027f3          	csrr	a5,sstatus
ffffffffc0202546:	8b89                	andi	a5,a5,2
ffffffffc0202548:	24079f63          	bnez	a5,ffffffffc02027a6 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc020254c:	000b3783          	ld	a5,0(s6)
ffffffffc0202550:	779c                	ld	a5,40(a5)
ffffffffc0202552:	9782                	jalr	a5
ffffffffc0202554:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202556:	6098                	ld	a4,0(s1)
ffffffffc0202558:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020255c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020255e:	00c71793          	slli	a5,a4,0xc
ffffffffc0202562:	6a05                	lui	s4,0x1
ffffffffc0202564:	02f47c63          	bgeu	s0,a5,ffffffffc020259c <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202568:	00c45793          	srli	a5,s0,0xc
ffffffffc020256c:	00093503          	ld	a0,0(s2)
ffffffffc0202570:	2ee7ff63          	bgeu	a5,a4,ffffffffc020286e <pmm_init+0x70c>
ffffffffc0202574:	0009b583          	ld	a1,0(s3)
ffffffffc0202578:	4601                	li	a2,0
ffffffffc020257a:	95a2                	add	a1,a1,s0
ffffffffc020257c:	fd8ff0ef          	jal	ra,ffffffffc0201d54 <get_pte>
ffffffffc0202580:	32050463          	beqz	a0,ffffffffc02028a8 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202584:	611c                	ld	a5,0(a0)
ffffffffc0202586:	078a                	slli	a5,a5,0x2
ffffffffc0202588:	0157f7b3          	and	a5,a5,s5
ffffffffc020258c:	2e879e63          	bne	a5,s0,ffffffffc0202888 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202590:	6098                	ld	a4,0(s1)
ffffffffc0202592:	9452                	add	s0,s0,s4
ffffffffc0202594:	00c71793          	slli	a5,a4,0xc
ffffffffc0202598:	fcf468e3          	bltu	s0,a5,ffffffffc0202568 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020259c:	00093783          	ld	a5,0(s2)
ffffffffc02025a0:	639c                	ld	a5,0(a5)
ffffffffc02025a2:	42079363          	bnez	a5,ffffffffc02029c8 <pmm_init+0x866>
ffffffffc02025a6:	100027f3          	csrr	a5,sstatus
ffffffffc02025aa:	8b89                	andi	a5,a5,2
ffffffffc02025ac:	24079963          	bnez	a5,ffffffffc02027fe <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025b0:	000b3783          	ld	a5,0(s6)
ffffffffc02025b4:	4505                	li	a0,1
ffffffffc02025b6:	6f9c                	ld	a5,24(a5)
ffffffffc02025b8:	9782                	jalr	a5
ffffffffc02025ba:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025bc:	00093503          	ld	a0,0(s2)
ffffffffc02025c0:	4699                	li	a3,6
ffffffffc02025c2:	10000613          	li	a2,256
ffffffffc02025c6:	85d2                	mv	a1,s4
ffffffffc02025c8:	aa5ff0ef          	jal	ra,ffffffffc020206c <page_insert>
ffffffffc02025cc:	44051e63          	bnez	a0,ffffffffc0202a28 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025d0:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025d4:	4785                	li	a5,1
ffffffffc02025d6:	42f71963          	bne	a4,a5,ffffffffc0202a08 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025da:	00093503          	ld	a0,0(s2)
ffffffffc02025de:	6405                	lui	s0,0x1
ffffffffc02025e0:	4699                	li	a3,6
ffffffffc02025e2:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025e6:	85d2                	mv	a1,s4
ffffffffc02025e8:	a85ff0ef          	jal	ra,ffffffffc020206c <page_insert>
ffffffffc02025ec:	72051363          	bnez	a0,ffffffffc0202d12 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02025f0:	000a2703          	lw	a4,0(s4)
ffffffffc02025f4:	4789                	li	a5,2
ffffffffc02025f6:	6ef71e63          	bne	a4,a5,ffffffffc0202cf2 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025fa:	00003597          	auipc	a1,0x3
ffffffffc02025fe:	d7658593          	addi	a1,a1,-650 # ffffffffc0205370 <default_pmm_manager+0x660>
ffffffffc0202602:	10000513          	li	a0,256
ffffffffc0202606:	01f010ef          	jal	ra,ffffffffc0203e24 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020260a:	10040593          	addi	a1,s0,256
ffffffffc020260e:	10000513          	li	a0,256
ffffffffc0202612:	025010ef          	jal	ra,ffffffffc0203e36 <strcmp>
ffffffffc0202616:	6a051e63          	bnez	a0,ffffffffc0202cd2 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020261a:	000bb683          	ld	a3,0(s7)
ffffffffc020261e:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202622:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202624:	40da06b3          	sub	a3,s4,a3
ffffffffc0202628:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020262a:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc020262c:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020262e:	8031                	srli	s0,s0,0xc
ffffffffc0202630:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202634:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202636:	30f77d63          	bgeu	a4,a5,ffffffffc0202950 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020263a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020263e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202642:	96be                	add	a3,a3,a5
ffffffffc0202644:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202648:	7a6010ef          	jal	ra,ffffffffc0203dee <strlen>
ffffffffc020264c:	66051363          	bnez	a0,ffffffffc0202cb2 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202650:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202654:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202656:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc020265a:	068a                	slli	a3,a3,0x2
ffffffffc020265c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020265e:	26f6f563          	bgeu	a3,a5,ffffffffc02028c8 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202662:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202664:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202666:	2ef47563          	bgeu	s0,a5,ffffffffc0202950 <pmm_init+0x7ee>
ffffffffc020266a:	0009b403          	ld	s0,0(s3)
ffffffffc020266e:	9436                	add	s0,s0,a3
ffffffffc0202670:	100027f3          	csrr	a5,sstatus
ffffffffc0202674:	8b89                	andi	a5,a5,2
ffffffffc0202676:	1e079163          	bnez	a5,ffffffffc0202858 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020267a:	000b3783          	ld	a5,0(s6)
ffffffffc020267e:	4585                	li	a1,1
ffffffffc0202680:	8552                	mv	a0,s4
ffffffffc0202682:	739c                	ld	a5,32(a5)
ffffffffc0202684:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202686:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202688:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020268a:	078a                	slli	a5,a5,0x2
ffffffffc020268c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020268e:	22e7fd63          	bgeu	a5,a4,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202692:	000bb503          	ld	a0,0(s7)
ffffffffc0202696:	fff80737          	lui	a4,0xfff80
ffffffffc020269a:	97ba                	add	a5,a5,a4
ffffffffc020269c:	079a                	slli	a5,a5,0x6
ffffffffc020269e:	953e                	add	a0,a0,a5
ffffffffc02026a0:	100027f3          	csrr	a5,sstatus
ffffffffc02026a4:	8b89                	andi	a5,a5,2
ffffffffc02026a6:	18079d63          	bnez	a5,ffffffffc0202840 <pmm_init+0x6de>
ffffffffc02026aa:	000b3783          	ld	a5,0(s6)
ffffffffc02026ae:	4585                	li	a1,1
ffffffffc02026b0:	739c                	ld	a5,32(a5)
ffffffffc02026b2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026b4:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02026b8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026ba:	078a                	slli	a5,a5,0x2
ffffffffc02026bc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026be:	20e7f563          	bgeu	a5,a4,ffffffffc02028c8 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026c2:	000bb503          	ld	a0,0(s7)
ffffffffc02026c6:	fff80737          	lui	a4,0xfff80
ffffffffc02026ca:	97ba                	add	a5,a5,a4
ffffffffc02026cc:	079a                	slli	a5,a5,0x6
ffffffffc02026ce:	953e                	add	a0,a0,a5
ffffffffc02026d0:	100027f3          	csrr	a5,sstatus
ffffffffc02026d4:	8b89                	andi	a5,a5,2
ffffffffc02026d6:	14079963          	bnez	a5,ffffffffc0202828 <pmm_init+0x6c6>
ffffffffc02026da:	000b3783          	ld	a5,0(s6)
ffffffffc02026de:	4585                	li	a1,1
ffffffffc02026e0:	739c                	ld	a5,32(a5)
ffffffffc02026e2:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026e4:	00093783          	ld	a5,0(s2)
ffffffffc02026e8:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026ec:	12000073          	sfence.vma
ffffffffc02026f0:	100027f3          	csrr	a5,sstatus
ffffffffc02026f4:	8b89                	andi	a5,a5,2
ffffffffc02026f6:	10079f63          	bnez	a5,ffffffffc0202814 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026fa:	000b3783          	ld	a5,0(s6)
ffffffffc02026fe:	779c                	ld	a5,40(a5)
ffffffffc0202700:	9782                	jalr	a5
ffffffffc0202702:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202704:	4c8c1e63          	bne	s8,s0,ffffffffc0202be0 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202708:	00003517          	auipc	a0,0x3
ffffffffc020270c:	ce050513          	addi	a0,a0,-800 # ffffffffc02053e8 <default_pmm_manager+0x6d8>
ffffffffc0202710:	a85fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202714:	7406                	ld	s0,96(sp)
ffffffffc0202716:	70a6                	ld	ra,104(sp)
ffffffffc0202718:	64e6                	ld	s1,88(sp)
ffffffffc020271a:	6946                	ld	s2,80(sp)
ffffffffc020271c:	69a6                	ld	s3,72(sp)
ffffffffc020271e:	6a06                	ld	s4,64(sp)
ffffffffc0202720:	7ae2                	ld	s5,56(sp)
ffffffffc0202722:	7b42                	ld	s6,48(sp)
ffffffffc0202724:	7ba2                	ld	s7,40(sp)
ffffffffc0202726:	7c02                	ld	s8,32(sp)
ffffffffc0202728:	6ce2                	ld	s9,24(sp)
ffffffffc020272a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc020272c:	b72ff06f          	j	ffffffffc0201a9e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202730:	c80007b7          	lui	a5,0xc8000
ffffffffc0202734:	bc7d                	j	ffffffffc02021f2 <pmm_init+0x90>
        intr_disable();
ffffffffc0202736:	9fafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020273a:	000b3783          	ld	a5,0(s6)
ffffffffc020273e:	4505                	li	a0,1
ffffffffc0202740:	6f9c                	ld	a5,24(a5)
ffffffffc0202742:	9782                	jalr	a5
ffffffffc0202744:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202746:	9e4fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020274a:	b9a9                	j	ffffffffc02023a4 <pmm_init+0x242>
        intr_disable();
ffffffffc020274c:	9e4fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202750:	000b3783          	ld	a5,0(s6)
ffffffffc0202754:	4505                	li	a0,1
ffffffffc0202756:	6f9c                	ld	a5,24(a5)
ffffffffc0202758:	9782                	jalr	a5
ffffffffc020275a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020275c:	9cefe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202760:	b645                	j	ffffffffc0202300 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202762:	9cefe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202766:	000b3783          	ld	a5,0(s6)
ffffffffc020276a:	779c                	ld	a5,40(a5)
ffffffffc020276c:	9782                	jalr	a5
ffffffffc020276e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202770:	9bafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202774:	b6b9                	j	ffffffffc02022c2 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202776:	6705                	lui	a4,0x1
ffffffffc0202778:	177d                	addi	a4,a4,-1
ffffffffc020277a:	96ba                	add	a3,a3,a4
ffffffffc020277c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc020277e:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202782:	14a77363          	bgeu	a4,a0,ffffffffc02028c8 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202786:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020278a:	fff80537          	lui	a0,0xfff80
ffffffffc020278e:	972a                	add	a4,a4,a0
ffffffffc0202790:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202792:	8c1d                	sub	s0,s0,a5
ffffffffc0202794:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202798:	00c45593          	srli	a1,s0,0xc
ffffffffc020279c:	9532                	add	a0,a0,a2
ffffffffc020279e:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027a0:	0009b583          	ld	a1,0(s3)
}
ffffffffc02027a4:	b4c1                	j	ffffffffc0202264 <pmm_init+0x102>
        intr_disable();
ffffffffc02027a6:	98afe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027aa:	000b3783          	ld	a5,0(s6)
ffffffffc02027ae:	779c                	ld	a5,40(a5)
ffffffffc02027b0:	9782                	jalr	a5
ffffffffc02027b2:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027b4:	976fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027b8:	bb79                	j	ffffffffc0202556 <pmm_init+0x3f4>
        intr_disable();
ffffffffc02027ba:	976fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027be:	000b3783          	ld	a5,0(s6)
ffffffffc02027c2:	779c                	ld	a5,40(a5)
ffffffffc02027c4:	9782                	jalr	a5
ffffffffc02027c6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027c8:	962fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027cc:	b39d                	j	ffffffffc0202532 <pmm_init+0x3d0>
ffffffffc02027ce:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d0:	960fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027d4:	000b3783          	ld	a5,0(s6)
ffffffffc02027d8:	6522                	ld	a0,8(sp)
ffffffffc02027da:	4585                	li	a1,1
ffffffffc02027dc:	739c                	ld	a5,32(a5)
ffffffffc02027de:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e0:	94afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027e4:	b33d                	j	ffffffffc0202512 <pmm_init+0x3b0>
ffffffffc02027e6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027e8:	948fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027ec:	000b3783          	ld	a5,0(s6)
ffffffffc02027f0:	6522                	ld	a0,8(sp)
ffffffffc02027f2:	4585                	li	a1,1
ffffffffc02027f4:	739c                	ld	a5,32(a5)
ffffffffc02027f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027f8:	932fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027fc:	b1dd                	j	ffffffffc02024e2 <pmm_init+0x380>
        intr_disable();
ffffffffc02027fe:	932fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202802:	000b3783          	ld	a5,0(s6)
ffffffffc0202806:	4505                	li	a0,1
ffffffffc0202808:	6f9c                	ld	a5,24(a5)
ffffffffc020280a:	9782                	jalr	a5
ffffffffc020280c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020280e:	91cfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202812:	b36d                	j	ffffffffc02025bc <pmm_init+0x45a>
        intr_disable();
ffffffffc0202814:	91cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202818:	000b3783          	ld	a5,0(s6)
ffffffffc020281c:	779c                	ld	a5,40(a5)
ffffffffc020281e:	9782                	jalr	a5
ffffffffc0202820:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202822:	908fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202826:	bdf9                	j	ffffffffc0202704 <pmm_init+0x5a2>
ffffffffc0202828:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020282a:	906fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020282e:	000b3783          	ld	a5,0(s6)
ffffffffc0202832:	6522                	ld	a0,8(sp)
ffffffffc0202834:	4585                	li	a1,1
ffffffffc0202836:	739c                	ld	a5,32(a5)
ffffffffc0202838:	9782                	jalr	a5
        intr_enable();
ffffffffc020283a:	8f0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020283e:	b55d                	j	ffffffffc02026e4 <pmm_init+0x582>
ffffffffc0202840:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202842:	8eefe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202846:	000b3783          	ld	a5,0(s6)
ffffffffc020284a:	6522                	ld	a0,8(sp)
ffffffffc020284c:	4585                	li	a1,1
ffffffffc020284e:	739c                	ld	a5,32(a5)
ffffffffc0202850:	9782                	jalr	a5
        intr_enable();
ffffffffc0202852:	8d8fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202856:	bdb9                	j	ffffffffc02026b4 <pmm_init+0x552>
        intr_disable();
ffffffffc0202858:	8d8fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020285c:	000b3783          	ld	a5,0(s6)
ffffffffc0202860:	4585                	li	a1,1
ffffffffc0202862:	8552                	mv	a0,s4
ffffffffc0202864:	739c                	ld	a5,32(a5)
ffffffffc0202866:	9782                	jalr	a5
        intr_enable();
ffffffffc0202868:	8c2fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020286c:	bd29                	j	ffffffffc0202686 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020286e:	86a2                	mv	a3,s0
ffffffffc0202870:	00002617          	auipc	a2,0x2
ffffffffc0202874:	4d860613          	addi	a2,a2,1240 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0202878:	1a400593          	li	a1,420
ffffffffc020287c:	00002517          	auipc	a0,0x2
ffffffffc0202880:	5e450513          	addi	a0,a0,1508 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202884:	bd7fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202888:	00003697          	auipc	a3,0x3
ffffffffc020288c:	a0068693          	addi	a3,a3,-1536 # ffffffffc0205288 <default_pmm_manager+0x578>
ffffffffc0202890:	00002617          	auipc	a2,0x2
ffffffffc0202894:	0d060613          	addi	a2,a2,208 # ffffffffc0204960 <commands+0x818>
ffffffffc0202898:	1a500593          	li	a1,421
ffffffffc020289c:	00002517          	auipc	a0,0x2
ffffffffc02028a0:	5c450513          	addi	a0,a0,1476 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02028a4:	bb7fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02028a8:	00003697          	auipc	a3,0x3
ffffffffc02028ac:	9a068693          	addi	a3,a3,-1632 # ffffffffc0205248 <default_pmm_manager+0x538>
ffffffffc02028b0:	00002617          	auipc	a2,0x2
ffffffffc02028b4:	0b060613          	addi	a2,a2,176 # ffffffffc0204960 <commands+0x818>
ffffffffc02028b8:	1a400593          	li	a1,420
ffffffffc02028bc:	00002517          	auipc	a0,0x2
ffffffffc02028c0:	5a450513          	addi	a0,a0,1444 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02028c4:	b97fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028c8:	b9cff0ef          	jal	ra,ffffffffc0201c64 <pa2page.part.0>
ffffffffc02028cc:	bb4ff0ef          	jal	ra,ffffffffc0201c80 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028d0:	00002697          	auipc	a3,0x2
ffffffffc02028d4:	77068693          	addi	a3,a3,1904 # ffffffffc0205040 <default_pmm_manager+0x330>
ffffffffc02028d8:	00002617          	auipc	a2,0x2
ffffffffc02028dc:	08860613          	addi	a2,a2,136 # ffffffffc0204960 <commands+0x818>
ffffffffc02028e0:	17400593          	li	a1,372
ffffffffc02028e4:	00002517          	auipc	a0,0x2
ffffffffc02028e8:	57c50513          	addi	a0,a0,1404 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02028ec:	b6ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028f0:	00002697          	auipc	a3,0x2
ffffffffc02028f4:	69068693          	addi	a3,a3,1680 # ffffffffc0204f80 <default_pmm_manager+0x270>
ffffffffc02028f8:	00002617          	auipc	a2,0x2
ffffffffc02028fc:	06860613          	addi	a2,a2,104 # ffffffffc0204960 <commands+0x818>
ffffffffc0202900:	16700593          	li	a1,359
ffffffffc0202904:	00002517          	auipc	a0,0x2
ffffffffc0202908:	55c50513          	addi	a0,a0,1372 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc020290c:	b4ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202910:	00002697          	auipc	a3,0x2
ffffffffc0202914:	63068693          	addi	a3,a3,1584 # ffffffffc0204f40 <default_pmm_manager+0x230>
ffffffffc0202918:	00002617          	auipc	a2,0x2
ffffffffc020291c:	04860613          	addi	a2,a2,72 # ffffffffc0204960 <commands+0x818>
ffffffffc0202920:	16600593          	li	a1,358
ffffffffc0202924:	00002517          	auipc	a0,0x2
ffffffffc0202928:	53c50513          	addi	a0,a0,1340 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc020292c:	b2ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202930:	00002697          	auipc	a3,0x2
ffffffffc0202934:	5f068693          	addi	a3,a3,1520 # ffffffffc0204f20 <default_pmm_manager+0x210>
ffffffffc0202938:	00002617          	auipc	a2,0x2
ffffffffc020293c:	02860613          	addi	a2,a2,40 # ffffffffc0204960 <commands+0x818>
ffffffffc0202940:	16500593          	li	a1,357
ffffffffc0202944:	00002517          	auipc	a0,0x2
ffffffffc0202948:	51c50513          	addi	a0,a0,1308 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc020294c:	b0ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202950:	00002617          	auipc	a2,0x2
ffffffffc0202954:	3f860613          	addi	a2,a2,1016 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0202958:	07100593          	li	a1,113
ffffffffc020295c:	00002517          	auipc	a0,0x2
ffffffffc0202960:	41450513          	addi	a0,a0,1044 # ffffffffc0204d70 <default_pmm_manager+0x60>
ffffffffc0202964:	af7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202968:	00003697          	auipc	a3,0x3
ffffffffc020296c:	86868693          	addi	a3,a3,-1944 # ffffffffc02051d0 <default_pmm_manager+0x4c0>
ffffffffc0202970:	00002617          	auipc	a2,0x2
ffffffffc0202974:	ff060613          	addi	a2,a2,-16 # ffffffffc0204960 <commands+0x818>
ffffffffc0202978:	18d00593          	li	a1,397
ffffffffc020297c:	00002517          	auipc	a0,0x2
ffffffffc0202980:	4e450513          	addi	a0,a0,1252 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202984:	ad7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202988:	00003697          	auipc	a3,0x3
ffffffffc020298c:	80068693          	addi	a3,a3,-2048 # ffffffffc0205188 <default_pmm_manager+0x478>
ffffffffc0202990:	00002617          	auipc	a2,0x2
ffffffffc0202994:	fd060613          	addi	a2,a2,-48 # ffffffffc0204960 <commands+0x818>
ffffffffc0202998:	18b00593          	li	a1,395
ffffffffc020299c:	00002517          	auipc	a0,0x2
ffffffffc02029a0:	4c450513          	addi	a0,a0,1220 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02029a4:	ab7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02029a8:	00003697          	auipc	a3,0x3
ffffffffc02029ac:	81068693          	addi	a3,a3,-2032 # ffffffffc02051b8 <default_pmm_manager+0x4a8>
ffffffffc02029b0:	00002617          	auipc	a2,0x2
ffffffffc02029b4:	fb060613          	addi	a2,a2,-80 # ffffffffc0204960 <commands+0x818>
ffffffffc02029b8:	18a00593          	li	a1,394
ffffffffc02029bc:	00002517          	auipc	a0,0x2
ffffffffc02029c0:	4a450513          	addi	a0,a0,1188 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02029c4:	a97fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029c8:	00003697          	auipc	a3,0x3
ffffffffc02029cc:	8d868693          	addi	a3,a3,-1832 # ffffffffc02052a0 <default_pmm_manager+0x590>
ffffffffc02029d0:	00002617          	auipc	a2,0x2
ffffffffc02029d4:	f9060613          	addi	a2,a2,-112 # ffffffffc0204960 <commands+0x818>
ffffffffc02029d8:	1a800593          	li	a1,424
ffffffffc02029dc:	00002517          	auipc	a0,0x2
ffffffffc02029e0:	48450513          	addi	a0,a0,1156 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc02029e4:	a77fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029e8:	00003697          	auipc	a3,0x3
ffffffffc02029ec:	81868693          	addi	a3,a3,-2024 # ffffffffc0205200 <default_pmm_manager+0x4f0>
ffffffffc02029f0:	00002617          	auipc	a2,0x2
ffffffffc02029f4:	f7060613          	addi	a2,a2,-144 # ffffffffc0204960 <commands+0x818>
ffffffffc02029f8:	19500593          	li	a1,405
ffffffffc02029fc:	00002517          	auipc	a0,0x2
ffffffffc0202a00:	46450513          	addi	a0,a0,1124 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202a04:	a57fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202a08:	00003697          	auipc	a3,0x3
ffffffffc0202a0c:	8f068693          	addi	a3,a3,-1808 # ffffffffc02052f8 <default_pmm_manager+0x5e8>
ffffffffc0202a10:	00002617          	auipc	a2,0x2
ffffffffc0202a14:	f5060613          	addi	a2,a2,-176 # ffffffffc0204960 <commands+0x818>
ffffffffc0202a18:	1ad00593          	li	a1,429
ffffffffc0202a1c:	00002517          	auipc	a0,0x2
ffffffffc0202a20:	44450513          	addi	a0,a0,1092 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202a24:	a37fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a28:	00003697          	auipc	a3,0x3
ffffffffc0202a2c:	89068693          	addi	a3,a3,-1904 # ffffffffc02052b8 <default_pmm_manager+0x5a8>
ffffffffc0202a30:	00002617          	auipc	a2,0x2
ffffffffc0202a34:	f3060613          	addi	a2,a2,-208 # ffffffffc0204960 <commands+0x818>
ffffffffc0202a38:	1ac00593          	li	a1,428
ffffffffc0202a3c:	00002517          	auipc	a0,0x2
ffffffffc0202a40:	42450513          	addi	a0,a0,1060 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202a44:	a17fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a48:	00002697          	auipc	a3,0x2
ffffffffc0202a4c:	74068693          	addi	a3,a3,1856 # ffffffffc0205188 <default_pmm_manager+0x478>
ffffffffc0202a50:	00002617          	auipc	a2,0x2
ffffffffc0202a54:	f1060613          	addi	a2,a2,-240 # ffffffffc0204960 <commands+0x818>
ffffffffc0202a58:	18700593          	li	a1,391
ffffffffc0202a5c:	00002517          	auipc	a0,0x2
ffffffffc0202a60:	40450513          	addi	a0,a0,1028 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202a64:	9f7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a68:	00002697          	auipc	a3,0x2
ffffffffc0202a6c:	5c068693          	addi	a3,a3,1472 # ffffffffc0205028 <default_pmm_manager+0x318>
ffffffffc0202a70:	00002617          	auipc	a2,0x2
ffffffffc0202a74:	ef060613          	addi	a2,a2,-272 # ffffffffc0204960 <commands+0x818>
ffffffffc0202a78:	18600593          	li	a1,390
ffffffffc0202a7c:	00002517          	auipc	a0,0x2
ffffffffc0202a80:	3e450513          	addi	a0,a0,996 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202a84:	9d7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a88:	00002697          	auipc	a3,0x2
ffffffffc0202a8c:	71868693          	addi	a3,a3,1816 # ffffffffc02051a0 <default_pmm_manager+0x490>
ffffffffc0202a90:	00002617          	auipc	a2,0x2
ffffffffc0202a94:	ed060613          	addi	a2,a2,-304 # ffffffffc0204960 <commands+0x818>
ffffffffc0202a98:	18300593          	li	a1,387
ffffffffc0202a9c:	00002517          	auipc	a0,0x2
ffffffffc0202aa0:	3c450513          	addi	a0,a0,964 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202aa4:	9b7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202aa8:	00002697          	auipc	a3,0x2
ffffffffc0202aac:	56868693          	addi	a3,a3,1384 # ffffffffc0205010 <default_pmm_manager+0x300>
ffffffffc0202ab0:	00002617          	auipc	a2,0x2
ffffffffc0202ab4:	eb060613          	addi	a2,a2,-336 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ab8:	18200593          	li	a1,386
ffffffffc0202abc:	00002517          	auipc	a0,0x2
ffffffffc0202ac0:	3a450513          	addi	a0,a0,932 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202ac4:	997fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ac8:	00002697          	auipc	a3,0x2
ffffffffc0202acc:	5e868693          	addi	a3,a3,1512 # ffffffffc02050b0 <default_pmm_manager+0x3a0>
ffffffffc0202ad0:	00002617          	auipc	a2,0x2
ffffffffc0202ad4:	e9060613          	addi	a2,a2,-368 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ad8:	18100593          	li	a1,385
ffffffffc0202adc:	00002517          	auipc	a0,0x2
ffffffffc0202ae0:	38450513          	addi	a0,a0,900 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202ae4:	977fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ae8:	00002697          	auipc	a3,0x2
ffffffffc0202aec:	6a068693          	addi	a3,a3,1696 # ffffffffc0205188 <default_pmm_manager+0x478>
ffffffffc0202af0:	00002617          	auipc	a2,0x2
ffffffffc0202af4:	e7060613          	addi	a2,a2,-400 # ffffffffc0204960 <commands+0x818>
ffffffffc0202af8:	18000593          	li	a1,384
ffffffffc0202afc:	00002517          	auipc	a0,0x2
ffffffffc0202b00:	36450513          	addi	a0,a0,868 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202b04:	957fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202b08:	00002697          	auipc	a3,0x2
ffffffffc0202b0c:	66868693          	addi	a3,a3,1640 # ffffffffc0205170 <default_pmm_manager+0x460>
ffffffffc0202b10:	00002617          	auipc	a2,0x2
ffffffffc0202b14:	e5060613          	addi	a2,a2,-432 # ffffffffc0204960 <commands+0x818>
ffffffffc0202b18:	17f00593          	li	a1,383
ffffffffc0202b1c:	00002517          	auipc	a0,0x2
ffffffffc0202b20:	34450513          	addi	a0,a0,836 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202b24:	937fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b28:	00002697          	auipc	a3,0x2
ffffffffc0202b2c:	61868693          	addi	a3,a3,1560 # ffffffffc0205140 <default_pmm_manager+0x430>
ffffffffc0202b30:	00002617          	auipc	a2,0x2
ffffffffc0202b34:	e3060613          	addi	a2,a2,-464 # ffffffffc0204960 <commands+0x818>
ffffffffc0202b38:	17e00593          	li	a1,382
ffffffffc0202b3c:	00002517          	auipc	a0,0x2
ffffffffc0202b40:	32450513          	addi	a0,a0,804 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202b44:	917fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b48:	00002697          	auipc	a3,0x2
ffffffffc0202b4c:	5e068693          	addi	a3,a3,1504 # ffffffffc0205128 <default_pmm_manager+0x418>
ffffffffc0202b50:	00002617          	auipc	a2,0x2
ffffffffc0202b54:	e1060613          	addi	a2,a2,-496 # ffffffffc0204960 <commands+0x818>
ffffffffc0202b58:	17c00593          	li	a1,380
ffffffffc0202b5c:	00002517          	auipc	a0,0x2
ffffffffc0202b60:	30450513          	addi	a0,a0,772 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202b64:	8f7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b68:	00002697          	auipc	a3,0x2
ffffffffc0202b6c:	5a068693          	addi	a3,a3,1440 # ffffffffc0205108 <default_pmm_manager+0x3f8>
ffffffffc0202b70:	00002617          	auipc	a2,0x2
ffffffffc0202b74:	df060613          	addi	a2,a2,-528 # ffffffffc0204960 <commands+0x818>
ffffffffc0202b78:	17b00593          	li	a1,379
ffffffffc0202b7c:	00002517          	auipc	a0,0x2
ffffffffc0202b80:	2e450513          	addi	a0,a0,740 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202b84:	8d7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b88:	00002697          	auipc	a3,0x2
ffffffffc0202b8c:	57068693          	addi	a3,a3,1392 # ffffffffc02050f8 <default_pmm_manager+0x3e8>
ffffffffc0202b90:	00002617          	auipc	a2,0x2
ffffffffc0202b94:	dd060613          	addi	a2,a2,-560 # ffffffffc0204960 <commands+0x818>
ffffffffc0202b98:	17a00593          	li	a1,378
ffffffffc0202b9c:	00002517          	auipc	a0,0x2
ffffffffc0202ba0:	2c450513          	addi	a0,a0,708 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202ba4:	8b7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202ba8:	00002697          	auipc	a3,0x2
ffffffffc0202bac:	54068693          	addi	a3,a3,1344 # ffffffffc02050e8 <default_pmm_manager+0x3d8>
ffffffffc0202bb0:	00002617          	auipc	a2,0x2
ffffffffc0202bb4:	db060613          	addi	a2,a2,-592 # ffffffffc0204960 <commands+0x818>
ffffffffc0202bb8:	17900593          	li	a1,377
ffffffffc0202bbc:	00002517          	auipc	a0,0x2
ffffffffc0202bc0:	2a450513          	addi	a0,a0,676 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202bc4:	897fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202bc8:	00002617          	auipc	a2,0x2
ffffffffc0202bcc:	2c060613          	addi	a2,a2,704 # ffffffffc0204e88 <default_pmm_manager+0x178>
ffffffffc0202bd0:	06400593          	li	a1,100
ffffffffc0202bd4:	00002517          	auipc	a0,0x2
ffffffffc0202bd8:	28c50513          	addi	a0,a0,652 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202bdc:	87ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202be0:	00002697          	auipc	a3,0x2
ffffffffc0202be4:	62068693          	addi	a3,a3,1568 # ffffffffc0205200 <default_pmm_manager+0x4f0>
ffffffffc0202be8:	00002617          	auipc	a2,0x2
ffffffffc0202bec:	d7860613          	addi	a2,a2,-648 # ffffffffc0204960 <commands+0x818>
ffffffffc0202bf0:	1bf00593          	li	a1,447
ffffffffc0202bf4:	00002517          	auipc	a0,0x2
ffffffffc0202bf8:	26c50513          	addi	a0,a0,620 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202bfc:	85ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202c00:	00002697          	auipc	a3,0x2
ffffffffc0202c04:	4b068693          	addi	a3,a3,1200 # ffffffffc02050b0 <default_pmm_manager+0x3a0>
ffffffffc0202c08:	00002617          	auipc	a2,0x2
ffffffffc0202c0c:	d5860613          	addi	a2,a2,-680 # ffffffffc0204960 <commands+0x818>
ffffffffc0202c10:	17800593          	li	a1,376
ffffffffc0202c14:	00002517          	auipc	a0,0x2
ffffffffc0202c18:	24c50513          	addi	a0,a0,588 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202c1c:	83ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c20:	00002697          	auipc	a3,0x2
ffffffffc0202c24:	45068693          	addi	a3,a3,1104 # ffffffffc0205070 <default_pmm_manager+0x360>
ffffffffc0202c28:	00002617          	auipc	a2,0x2
ffffffffc0202c2c:	d3860613          	addi	a2,a2,-712 # ffffffffc0204960 <commands+0x818>
ffffffffc0202c30:	17700593          	li	a1,375
ffffffffc0202c34:	00002517          	auipc	a0,0x2
ffffffffc0202c38:	22c50513          	addi	a0,a0,556 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202c3c:	81ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c40:	86d6                	mv	a3,s5
ffffffffc0202c42:	00002617          	auipc	a2,0x2
ffffffffc0202c46:	10660613          	addi	a2,a2,262 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0202c4a:	17300593          	li	a1,371
ffffffffc0202c4e:	00002517          	auipc	a0,0x2
ffffffffc0202c52:	21250513          	addi	a0,a0,530 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202c56:	805fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c5a:	00002617          	auipc	a2,0x2
ffffffffc0202c5e:	0ee60613          	addi	a2,a2,238 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc0202c62:	17200593          	li	a1,370
ffffffffc0202c66:	00002517          	auipc	a0,0x2
ffffffffc0202c6a:	1fa50513          	addi	a0,a0,506 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202c6e:	fecfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c72:	00002697          	auipc	a3,0x2
ffffffffc0202c76:	3b668693          	addi	a3,a3,950 # ffffffffc0205028 <default_pmm_manager+0x318>
ffffffffc0202c7a:	00002617          	auipc	a2,0x2
ffffffffc0202c7e:	ce660613          	addi	a2,a2,-794 # ffffffffc0204960 <commands+0x818>
ffffffffc0202c82:	17000593          	li	a1,368
ffffffffc0202c86:	00002517          	auipc	a0,0x2
ffffffffc0202c8a:	1da50513          	addi	a0,a0,474 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202c8e:	fccfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c92:	00002697          	auipc	a3,0x2
ffffffffc0202c96:	37e68693          	addi	a3,a3,894 # ffffffffc0205010 <default_pmm_manager+0x300>
ffffffffc0202c9a:	00002617          	auipc	a2,0x2
ffffffffc0202c9e:	cc660613          	addi	a2,a2,-826 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ca2:	16f00593          	li	a1,367
ffffffffc0202ca6:	00002517          	auipc	a0,0x2
ffffffffc0202caa:	1ba50513          	addi	a0,a0,442 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202cae:	facfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cb2:	00002697          	auipc	a3,0x2
ffffffffc0202cb6:	70e68693          	addi	a3,a3,1806 # ffffffffc02053c0 <default_pmm_manager+0x6b0>
ffffffffc0202cba:	00002617          	auipc	a2,0x2
ffffffffc0202cbe:	ca660613          	addi	a2,a2,-858 # ffffffffc0204960 <commands+0x818>
ffffffffc0202cc2:	1b600593          	li	a1,438
ffffffffc0202cc6:	00002517          	auipc	a0,0x2
ffffffffc0202cca:	19a50513          	addi	a0,a0,410 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202cce:	f8cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cd2:	00002697          	auipc	a3,0x2
ffffffffc0202cd6:	6b668693          	addi	a3,a3,1718 # ffffffffc0205388 <default_pmm_manager+0x678>
ffffffffc0202cda:	00002617          	auipc	a2,0x2
ffffffffc0202cde:	c8660613          	addi	a2,a2,-890 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ce2:	1b300593          	li	a1,435
ffffffffc0202ce6:	00002517          	auipc	a0,0x2
ffffffffc0202cea:	17a50513          	addi	a0,a0,378 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202cee:	f6cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202cf2:	00002697          	auipc	a3,0x2
ffffffffc0202cf6:	66668693          	addi	a3,a3,1638 # ffffffffc0205358 <default_pmm_manager+0x648>
ffffffffc0202cfa:	00002617          	auipc	a2,0x2
ffffffffc0202cfe:	c6660613          	addi	a2,a2,-922 # ffffffffc0204960 <commands+0x818>
ffffffffc0202d02:	1af00593          	li	a1,431
ffffffffc0202d06:	00002517          	auipc	a0,0x2
ffffffffc0202d0a:	15a50513          	addi	a0,a0,346 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d0e:	f4cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d12:	00002697          	auipc	a3,0x2
ffffffffc0202d16:	5fe68693          	addi	a3,a3,1534 # ffffffffc0205310 <default_pmm_manager+0x600>
ffffffffc0202d1a:	00002617          	auipc	a2,0x2
ffffffffc0202d1e:	c4660613          	addi	a2,a2,-954 # ffffffffc0204960 <commands+0x818>
ffffffffc0202d22:	1ae00593          	li	a1,430
ffffffffc0202d26:	00002517          	auipc	a0,0x2
ffffffffc0202d2a:	13a50513          	addi	a0,a0,314 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d2e:	f2cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d32:	00002617          	auipc	a2,0x2
ffffffffc0202d36:	0be60613          	addi	a2,a2,190 # ffffffffc0204df0 <default_pmm_manager+0xe0>
ffffffffc0202d3a:	0cb00593          	li	a1,203
ffffffffc0202d3e:	00002517          	auipc	a0,0x2
ffffffffc0202d42:	12250513          	addi	a0,a0,290 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d46:	f14fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d4a:	00002617          	auipc	a2,0x2
ffffffffc0202d4e:	0a660613          	addi	a2,a2,166 # ffffffffc0204df0 <default_pmm_manager+0xe0>
ffffffffc0202d52:	08000593          	li	a1,128
ffffffffc0202d56:	00002517          	auipc	a0,0x2
ffffffffc0202d5a:	10a50513          	addi	a0,a0,266 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d5e:	efcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d62:	00002697          	auipc	a3,0x2
ffffffffc0202d66:	27e68693          	addi	a3,a3,638 # ffffffffc0204fe0 <default_pmm_manager+0x2d0>
ffffffffc0202d6a:	00002617          	auipc	a2,0x2
ffffffffc0202d6e:	bf660613          	addi	a2,a2,-1034 # ffffffffc0204960 <commands+0x818>
ffffffffc0202d72:	16e00593          	li	a1,366
ffffffffc0202d76:	00002517          	auipc	a0,0x2
ffffffffc0202d7a:	0ea50513          	addi	a0,a0,234 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d7e:	edcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d82:	00002697          	auipc	a3,0x2
ffffffffc0202d86:	22e68693          	addi	a3,a3,558 # ffffffffc0204fb0 <default_pmm_manager+0x2a0>
ffffffffc0202d8a:	00002617          	auipc	a2,0x2
ffffffffc0202d8e:	bd660613          	addi	a2,a2,-1066 # ffffffffc0204960 <commands+0x818>
ffffffffc0202d92:	16b00593          	li	a1,363
ffffffffc0202d96:	00002517          	auipc	a0,0x2
ffffffffc0202d9a:	0ca50513          	addi	a0,a0,202 # ffffffffc0204e60 <default_pmm_manager+0x150>
ffffffffc0202d9e:	ebcfd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202da2 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202da2:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202da4:	00002697          	auipc	a3,0x2
ffffffffc0202da8:	66468693          	addi	a3,a3,1636 # ffffffffc0205408 <default_pmm_manager+0x6f8>
ffffffffc0202dac:	00002617          	auipc	a2,0x2
ffffffffc0202db0:	bb460613          	addi	a2,a2,-1100 # ffffffffc0204960 <commands+0x818>
ffffffffc0202db4:	08800593          	li	a1,136
ffffffffc0202db8:	00002517          	auipc	a0,0x2
ffffffffc0202dbc:	67050513          	addi	a0,a0,1648 # ffffffffc0205428 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dc0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202dc2:	e98fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202dc6 <find_vma>:
{
ffffffffc0202dc6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202dc8:	c505                	beqz	a0,ffffffffc0202df0 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202dca:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dcc:	c501                	beqz	a0,ffffffffc0202dd4 <find_vma+0xe>
ffffffffc0202dce:	651c                	ld	a5,8(a0)
ffffffffc0202dd0:	02f5f263          	bgeu	a1,a5,ffffffffc0202df4 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dd4:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dd6:	00f68d63          	beq	a3,a5,ffffffffc0202df0 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dda:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202dde:	00e5e663          	bltu	a1,a4,ffffffffc0202dea <find_vma+0x24>
ffffffffc0202de2:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202de6:	00e5ec63          	bltu	a1,a4,ffffffffc0202dfe <find_vma+0x38>
ffffffffc0202dea:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202dec:	fef697e3          	bne	a3,a5,ffffffffc0202dda <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202df0:	4501                	li	a0,0
}
ffffffffc0202df2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202df4:	691c                	ld	a5,16(a0)
ffffffffc0202df6:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202dd4 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202dfa:	ea88                	sd	a0,16(a3)
ffffffffc0202dfc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202dfe:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202e02:	ea88                	sd	a0,16(a3)
ffffffffc0202e04:	8082                	ret

ffffffffc0202e06 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e06:	6590                	ld	a2,8(a1)
ffffffffc0202e08:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e0c:	1141                	addi	sp,sp,-16
ffffffffc0202e0e:	e406                	sd	ra,8(sp)
ffffffffc0202e10:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e12:	01066763          	bltu	a2,a6,ffffffffc0202e20 <insert_vma_struct+0x1a>
ffffffffc0202e16:	a085                	j	ffffffffc0202e76 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e18:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e1c:	04e66863          	bltu	a2,a4,ffffffffc0202e6c <insert_vma_struct+0x66>
ffffffffc0202e20:	86be                	mv	a3,a5
ffffffffc0202e22:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e24:	fef51ae3          	bne	a0,a5,ffffffffc0202e18 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e28:	02a68463          	beq	a3,a0,ffffffffc0202e50 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e2c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e30:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e34:	08e8f163          	bgeu	a7,a4,ffffffffc0202eb6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e38:	04e66f63          	bltu	a2,a4,ffffffffc0202e96 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e3c:	00f50a63          	beq	a0,a5,ffffffffc0202e50 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e40:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e44:	05076963          	bltu	a4,a6,ffffffffc0202e96 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e48:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e4c:	02c77363          	bgeu	a4,a2,ffffffffc0202e72 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e50:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e52:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e54:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e58:	e390                	sd	a2,0(a5)
ffffffffc0202e5a:	e690                	sd	a2,8(a3)
}
ffffffffc0202e5c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e5e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e60:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e62:	0017079b          	addiw	a5,a4,1
ffffffffc0202e66:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e68:	0141                	addi	sp,sp,16
ffffffffc0202e6a:	8082                	ret
    if (le_prev != list)
ffffffffc0202e6c:	fca690e3          	bne	a3,a0,ffffffffc0202e2c <insert_vma_struct+0x26>
ffffffffc0202e70:	bfd1                	j	ffffffffc0202e44 <insert_vma_struct+0x3e>
ffffffffc0202e72:	f31ff0ef          	jal	ra,ffffffffc0202da2 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e76:	00002697          	auipc	a3,0x2
ffffffffc0202e7a:	5c268693          	addi	a3,a3,1474 # ffffffffc0205438 <default_pmm_manager+0x728>
ffffffffc0202e7e:	00002617          	auipc	a2,0x2
ffffffffc0202e82:	ae260613          	addi	a2,a2,-1310 # ffffffffc0204960 <commands+0x818>
ffffffffc0202e86:	08e00593          	li	a1,142
ffffffffc0202e8a:	00002517          	auipc	a0,0x2
ffffffffc0202e8e:	59e50513          	addi	a0,a0,1438 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0202e92:	dc8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e96:	00002697          	auipc	a3,0x2
ffffffffc0202e9a:	5e268693          	addi	a3,a3,1506 # ffffffffc0205478 <default_pmm_manager+0x768>
ffffffffc0202e9e:	00002617          	auipc	a2,0x2
ffffffffc0202ea2:	ac260613          	addi	a2,a2,-1342 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ea6:	08700593          	li	a1,135
ffffffffc0202eaa:	00002517          	auipc	a0,0x2
ffffffffc0202eae:	57e50513          	addi	a0,a0,1406 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0202eb2:	da8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eb6:	00002697          	auipc	a3,0x2
ffffffffc0202eba:	5a268693          	addi	a3,a3,1442 # ffffffffc0205458 <default_pmm_manager+0x748>
ffffffffc0202ebe:	00002617          	auipc	a2,0x2
ffffffffc0202ec2:	aa260613          	addi	a2,a2,-1374 # ffffffffc0204960 <commands+0x818>
ffffffffc0202ec6:	08600593          	li	a1,134
ffffffffc0202eca:	00002517          	auipc	a0,0x2
ffffffffc0202ece:	55e50513          	addi	a0,a0,1374 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0202ed2:	d88fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202ed6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202ed6:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ed8:	03000513          	li	a0,48
{
ffffffffc0202edc:	fc06                	sd	ra,56(sp)
ffffffffc0202ede:	f822                	sd	s0,48(sp)
ffffffffc0202ee0:	f426                	sd	s1,40(sp)
ffffffffc0202ee2:	f04a                	sd	s2,32(sp)
ffffffffc0202ee4:	ec4e                	sd	s3,24(sp)
ffffffffc0202ee6:	e852                	sd	s4,16(sp)
ffffffffc0202ee8:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202eea:	bd5fe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
    if (mm != NULL)
ffffffffc0202eee:	2e050f63          	beqz	a0,ffffffffc02031ec <vmm_init+0x316>
ffffffffc0202ef2:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202ef4:	e508                	sd	a0,8(a0)
ffffffffc0202ef6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ef8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202efc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202f00:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202f04:	02053423          	sd	zero,40(a0)
ffffffffc0202f08:	03200413          	li	s0,50
ffffffffc0202f0c:	a811                	j	ffffffffc0202f20 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202f0e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f10:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f12:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202f16:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f18:	8526                	mv	a0,s1
ffffffffc0202f1a:	eedff0ef          	jal	ra,ffffffffc0202e06 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f1e:	c80d                	beqz	s0,ffffffffc0202f50 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f20:	03000513          	li	a0,48
ffffffffc0202f24:	b9bfe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
ffffffffc0202f28:	85aa                	mv	a1,a0
ffffffffc0202f2a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f2e:	f165                	bnez	a0,ffffffffc0202f0e <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f30:	00002697          	auipc	a3,0x2
ffffffffc0202f34:	6e068693          	addi	a3,a3,1760 # ffffffffc0205610 <default_pmm_manager+0x900>
ffffffffc0202f38:	00002617          	auipc	a2,0x2
ffffffffc0202f3c:	a2860613          	addi	a2,a2,-1496 # ffffffffc0204960 <commands+0x818>
ffffffffc0202f40:	0da00593          	li	a1,218
ffffffffc0202f44:	00002517          	auipc	a0,0x2
ffffffffc0202f48:	4e450513          	addi	a0,a0,1252 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0202f4c:	d0efd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f50:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f54:	1f900913          	li	s2,505
ffffffffc0202f58:	a819                	j	ffffffffc0202f6e <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f5a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f5c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f5e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f62:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f64:	8526                	mv	a0,s1
ffffffffc0202f66:	ea1ff0ef          	jal	ra,ffffffffc0202e06 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f6a:	03240a63          	beq	s0,s2,ffffffffc0202f9e <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f6e:	03000513          	li	a0,48
ffffffffc0202f72:	b4dfe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
ffffffffc0202f76:	85aa                	mv	a1,a0
ffffffffc0202f78:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f7c:	fd79                	bnez	a0,ffffffffc0202f5a <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f7e:	00002697          	auipc	a3,0x2
ffffffffc0202f82:	69268693          	addi	a3,a3,1682 # ffffffffc0205610 <default_pmm_manager+0x900>
ffffffffc0202f86:	00002617          	auipc	a2,0x2
ffffffffc0202f8a:	9da60613          	addi	a2,a2,-1574 # ffffffffc0204960 <commands+0x818>
ffffffffc0202f8e:	0e100593          	li	a1,225
ffffffffc0202f92:	00002517          	auipc	a0,0x2
ffffffffc0202f96:	49650513          	addi	a0,a0,1174 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0202f9a:	cc0fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f9e:	649c                	ld	a5,8(s1)
ffffffffc0202fa0:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202fa2:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202fa6:	18f48363          	beq	s1,a5,ffffffffc020312c <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202faa:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202fae:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202fb2:	10d61d63          	bne	a2,a3,ffffffffc02030cc <vmm_init+0x1f6>
ffffffffc0202fb6:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202fba:	10e69963          	bne	a3,a4,ffffffffc02030cc <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fbe:	0715                	addi	a4,a4,5
ffffffffc0202fc0:	679c                	ld	a5,8(a5)
ffffffffc0202fc2:	feb712e3          	bne	a4,a1,ffffffffc0202fa6 <vmm_init+0xd0>
ffffffffc0202fc6:	4a1d                	li	s4,7
ffffffffc0202fc8:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fca:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fce:	85a2                	mv	a1,s0
ffffffffc0202fd0:	8526                	mv	a0,s1
ffffffffc0202fd2:	df5ff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
ffffffffc0202fd6:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202fd8:	18050a63          	beqz	a0,ffffffffc020316c <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202fdc:	00140593          	addi	a1,s0,1
ffffffffc0202fe0:	8526                	mv	a0,s1
ffffffffc0202fe2:	de5ff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
ffffffffc0202fe6:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fe8:	16050263          	beqz	a0,ffffffffc020314c <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202fec:	85d2                	mv	a1,s4
ffffffffc0202fee:	8526                	mv	a0,s1
ffffffffc0202ff0:	dd7ff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202ff4:	18051c63          	bnez	a0,ffffffffc020318c <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202ff8:	00340593          	addi	a1,s0,3
ffffffffc0202ffc:	8526                	mv	a0,s1
ffffffffc0202ffe:	dc9ff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203002:	1c051563          	bnez	a0,ffffffffc02031cc <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203006:	00440593          	addi	a1,s0,4
ffffffffc020300a:	8526                	mv	a0,s1
ffffffffc020300c:	dbbff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203010:	18051e63          	bnez	a0,ffffffffc02031ac <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203014:	00893783          	ld	a5,8(s2)
ffffffffc0203018:	0c879a63          	bne	a5,s0,ffffffffc02030ec <vmm_init+0x216>
ffffffffc020301c:	01093783          	ld	a5,16(s2)
ffffffffc0203020:	0d479663          	bne	a5,s4,ffffffffc02030ec <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203024:	0089b783          	ld	a5,8(s3)
ffffffffc0203028:	0e879263          	bne	a5,s0,ffffffffc020310c <vmm_init+0x236>
ffffffffc020302c:	0109b783          	ld	a5,16(s3)
ffffffffc0203030:	0d479e63          	bne	a5,s4,ffffffffc020310c <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203034:	0415                	addi	s0,s0,5
ffffffffc0203036:	0a15                	addi	s4,s4,5
ffffffffc0203038:	f9541be3          	bne	s0,s5,ffffffffc0202fce <vmm_init+0xf8>
ffffffffc020303c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020303e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203040:	85a2                	mv	a1,s0
ffffffffc0203042:	8526                	mv	a0,s1
ffffffffc0203044:	d83ff0ef          	jal	ra,ffffffffc0202dc6 <find_vma>
ffffffffc0203048:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc020304c:	c90d                	beqz	a0,ffffffffc020307e <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020304e:	6914                	ld	a3,16(a0)
ffffffffc0203050:	6510                	ld	a2,8(a0)
ffffffffc0203052:	00002517          	auipc	a0,0x2
ffffffffc0203056:	54650513          	addi	a0,a0,1350 # ffffffffc0205598 <default_pmm_manager+0x888>
ffffffffc020305a:	93afd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020305e:	00002697          	auipc	a3,0x2
ffffffffc0203062:	56268693          	addi	a3,a3,1378 # ffffffffc02055c0 <default_pmm_manager+0x8b0>
ffffffffc0203066:	00002617          	auipc	a2,0x2
ffffffffc020306a:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0204960 <commands+0x818>
ffffffffc020306e:	10700593          	li	a1,263
ffffffffc0203072:	00002517          	auipc	a0,0x2
ffffffffc0203076:	3b650513          	addi	a0,a0,950 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc020307a:	be0fd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc020307e:	147d                	addi	s0,s0,-1
ffffffffc0203080:	fd2410e3          	bne	s0,s2,ffffffffc0203040 <vmm_init+0x16a>
ffffffffc0203084:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0203086:	00a48c63          	beq	s1,a0,ffffffffc020309e <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020308a:	6118                	ld	a4,0(a0)
ffffffffc020308c:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020308e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203090:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203092:	e398                	sd	a4,0(a5)
ffffffffc0203094:	adbfe0ef          	jal	ra,ffffffffc0201b6e <kfree>
    return listelm->next;
ffffffffc0203098:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020309a:	fea498e3          	bne	s1,a0,ffffffffc020308a <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc020309e:	8526                	mv	a0,s1
ffffffffc02030a0:	acffe0ef          	jal	ra,ffffffffc0201b6e <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02030a4:	00002517          	auipc	a0,0x2
ffffffffc02030a8:	53450513          	addi	a0,a0,1332 # ffffffffc02055d8 <default_pmm_manager+0x8c8>
ffffffffc02030ac:	8e8fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030b0:	7442                	ld	s0,48(sp)
ffffffffc02030b2:	70e2                	ld	ra,56(sp)
ffffffffc02030b4:	74a2                	ld	s1,40(sp)
ffffffffc02030b6:	7902                	ld	s2,32(sp)
ffffffffc02030b8:	69e2                	ld	s3,24(sp)
ffffffffc02030ba:	6a42                	ld	s4,16(sp)
ffffffffc02030bc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030be:	00002517          	auipc	a0,0x2
ffffffffc02030c2:	53a50513          	addi	a0,a0,1338 # ffffffffc02055f8 <default_pmm_manager+0x8e8>
}
ffffffffc02030c6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030c8:	8ccfd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030cc:	00002697          	auipc	a3,0x2
ffffffffc02030d0:	3e468693          	addi	a3,a3,996 # ffffffffc02054b0 <default_pmm_manager+0x7a0>
ffffffffc02030d4:	00002617          	auipc	a2,0x2
ffffffffc02030d8:	88c60613          	addi	a2,a2,-1908 # ffffffffc0204960 <commands+0x818>
ffffffffc02030dc:	0eb00593          	li	a1,235
ffffffffc02030e0:	00002517          	auipc	a0,0x2
ffffffffc02030e4:	34850513          	addi	a0,a0,840 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc02030e8:	b72fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030ec:	00002697          	auipc	a3,0x2
ffffffffc02030f0:	44c68693          	addi	a3,a3,1100 # ffffffffc0205538 <default_pmm_manager+0x828>
ffffffffc02030f4:	00002617          	auipc	a2,0x2
ffffffffc02030f8:	86c60613          	addi	a2,a2,-1940 # ffffffffc0204960 <commands+0x818>
ffffffffc02030fc:	0fc00593          	li	a1,252
ffffffffc0203100:	00002517          	auipc	a0,0x2
ffffffffc0203104:	32850513          	addi	a0,a0,808 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203108:	b52fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020310c:	00002697          	auipc	a3,0x2
ffffffffc0203110:	45c68693          	addi	a3,a3,1116 # ffffffffc0205568 <default_pmm_manager+0x858>
ffffffffc0203114:	00002617          	auipc	a2,0x2
ffffffffc0203118:	84c60613          	addi	a2,a2,-1972 # ffffffffc0204960 <commands+0x818>
ffffffffc020311c:	0fd00593          	li	a1,253
ffffffffc0203120:	00002517          	auipc	a0,0x2
ffffffffc0203124:	30850513          	addi	a0,a0,776 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203128:	b32fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020312c:	00002697          	auipc	a3,0x2
ffffffffc0203130:	36c68693          	addi	a3,a3,876 # ffffffffc0205498 <default_pmm_manager+0x788>
ffffffffc0203134:	00002617          	auipc	a2,0x2
ffffffffc0203138:	82c60613          	addi	a2,a2,-2004 # ffffffffc0204960 <commands+0x818>
ffffffffc020313c:	0e900593          	li	a1,233
ffffffffc0203140:	00002517          	auipc	a0,0x2
ffffffffc0203144:	2e850513          	addi	a0,a0,744 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203148:	b12fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc020314c:	00002697          	auipc	a3,0x2
ffffffffc0203150:	3ac68693          	addi	a3,a3,940 # ffffffffc02054f8 <default_pmm_manager+0x7e8>
ffffffffc0203154:	00002617          	auipc	a2,0x2
ffffffffc0203158:	80c60613          	addi	a2,a2,-2036 # ffffffffc0204960 <commands+0x818>
ffffffffc020315c:	0f400593          	li	a1,244
ffffffffc0203160:	00002517          	auipc	a0,0x2
ffffffffc0203164:	2c850513          	addi	a0,a0,712 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203168:	af2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc020316c:	00002697          	auipc	a3,0x2
ffffffffc0203170:	37c68693          	addi	a3,a3,892 # ffffffffc02054e8 <default_pmm_manager+0x7d8>
ffffffffc0203174:	00001617          	auipc	a2,0x1
ffffffffc0203178:	7ec60613          	addi	a2,a2,2028 # ffffffffc0204960 <commands+0x818>
ffffffffc020317c:	0f200593          	li	a1,242
ffffffffc0203180:	00002517          	auipc	a0,0x2
ffffffffc0203184:	2a850513          	addi	a0,a0,680 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203188:	ad2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc020318c:	00002697          	auipc	a3,0x2
ffffffffc0203190:	37c68693          	addi	a3,a3,892 # ffffffffc0205508 <default_pmm_manager+0x7f8>
ffffffffc0203194:	00001617          	auipc	a2,0x1
ffffffffc0203198:	7cc60613          	addi	a2,a2,1996 # ffffffffc0204960 <commands+0x818>
ffffffffc020319c:	0f600593          	li	a1,246
ffffffffc02031a0:	00002517          	auipc	a0,0x2
ffffffffc02031a4:	28850513          	addi	a0,a0,648 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc02031a8:	ab2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc02031ac:	00002697          	auipc	a3,0x2
ffffffffc02031b0:	37c68693          	addi	a3,a3,892 # ffffffffc0205528 <default_pmm_manager+0x818>
ffffffffc02031b4:	00001617          	auipc	a2,0x1
ffffffffc02031b8:	7ac60613          	addi	a2,a2,1964 # ffffffffc0204960 <commands+0x818>
ffffffffc02031bc:	0fa00593          	li	a1,250
ffffffffc02031c0:	00002517          	auipc	a0,0x2
ffffffffc02031c4:	26850513          	addi	a0,a0,616 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc02031c8:	a92fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031cc:	00002697          	auipc	a3,0x2
ffffffffc02031d0:	34c68693          	addi	a3,a3,844 # ffffffffc0205518 <default_pmm_manager+0x808>
ffffffffc02031d4:	00001617          	auipc	a2,0x1
ffffffffc02031d8:	78c60613          	addi	a2,a2,1932 # ffffffffc0204960 <commands+0x818>
ffffffffc02031dc:	0f800593          	li	a1,248
ffffffffc02031e0:	00002517          	auipc	a0,0x2
ffffffffc02031e4:	24850513          	addi	a0,a0,584 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc02031e8:	a72fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc02031ec:	00002697          	auipc	a3,0x2
ffffffffc02031f0:	43468693          	addi	a3,a3,1076 # ffffffffc0205620 <default_pmm_manager+0x910>
ffffffffc02031f4:	00001617          	auipc	a2,0x1
ffffffffc02031f8:	76c60613          	addi	a2,a2,1900 # ffffffffc0204960 <commands+0x818>
ffffffffc02031fc:	0d200593          	li	a1,210
ffffffffc0203200:	00002517          	auipc	a0,0x2
ffffffffc0203204:	22850513          	addi	a0,a0,552 # ffffffffc0205428 <default_pmm_manager+0x718>
ffffffffc0203208:	a52fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020320c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc020320c:	8526                	mv	a0,s1
	jalr s0
ffffffffc020320e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203210:	424000ef          	jal	ra,ffffffffc0203634 <do_exit>

ffffffffc0203214 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203214:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203216:	0e800513          	li	a0,232
{
ffffffffc020321a:	e022                	sd	s0,0(sp)
ffffffffc020321c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020321e:	8a1fe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
ffffffffc0203222:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203224:	c521                	beqz	a0,ffffffffc020326c <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;      // 设置进程状态为未初始化
ffffffffc0203226:	57fd                	li	a5,-1
ffffffffc0203228:	1782                	slli	a5,a5,0x20
ffffffffc020322a:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                 // 运行时间为0
        proc->kstack = 0;               // 内核栈地址初始化为0
        proc->need_resched = 0;         // 不需要调度
        proc->parent = NULL;            // 父进程为空
        proc->mm = NULL;                // 内存管理结构为空,内核线程共享内核内存
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文
ffffffffc020322c:	07000613          	li	a2,112
ffffffffc0203230:	4581                	li	a1,0
        proc->runs = 0;                 // 运行时间为0
ffffffffc0203232:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;               // 内核栈地址初始化为0
ffffffffc0203236:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;         // 不需要调度
ffffffffc020323a:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;            // 父进程为空
ffffffffc020323e:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                // 内存管理结构为空,内核线程共享内核内存
ffffffffc0203242:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文
ffffffffc0203246:	03050513          	addi	a0,a0,48
ffffffffc020324a:	447000ef          	jal	ra,ffffffffc0203e90 <memset>
        proc->tf = NULL;                // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa;    // 页目录设为内核页目录的物理地址
ffffffffc020324e:	0000a797          	auipc	a5,0xa
ffffffffc0203252:	2527b783          	ld	a5,594(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
        proc->tf = NULL;                // 中断帧指针为空
ffffffffc0203256:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录设为内核页目录的物理地址
ffffffffc020325a:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // 标志位初始化
ffffffffc020325c:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 清空进程名
ffffffffc0203260:	4641                	li	a2,16
ffffffffc0203262:	4581                	li	a1,0
ffffffffc0203264:	0b440513          	addi	a0,s0,180
ffffffffc0203268:	429000ef          	jal	ra,ffffffffc0203e90 <memset>
    }
    return proc;
}
ffffffffc020326c:	60a2                	ld	ra,8(sp)
ffffffffc020326e:	8522                	mv	a0,s0
ffffffffc0203270:	6402                	ld	s0,0(sp)
ffffffffc0203272:	0141                	addi	sp,sp,16
ffffffffc0203274:	8082                	ret

ffffffffc0203276 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203276:	0000a797          	auipc	a5,0xa
ffffffffc020327a:	25a7b783          	ld	a5,602(a5) # ffffffffc020d4d0 <current>
ffffffffc020327e:	73c8                	ld	a0,160(a5)
ffffffffc0203280:	b5dfd06f          	j	ffffffffc0200ddc <forkrets>

ffffffffc0203284 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203284:	7179                	addi	sp,sp,-48
ffffffffc0203286:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203288:	0000a497          	auipc	s1,0xa
ffffffffc020328c:	1c048493          	addi	s1,s1,448 # ffffffffc020d448 <name.2>
{
ffffffffc0203290:	f022                	sd	s0,32(sp)
ffffffffc0203292:	e84a                	sd	s2,16(sp)
ffffffffc0203294:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203296:	0000a917          	auipc	s2,0xa
ffffffffc020329a:	23a93903          	ld	s2,570(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc020329e:	4641                	li	a2,16
ffffffffc02032a0:	4581                	li	a1,0
ffffffffc02032a2:	8526                	mv	a0,s1
{
ffffffffc02032a4:	f406                	sd	ra,40(sp)
ffffffffc02032a6:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032a8:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02032ac:	3e5000ef          	jal	ra,ffffffffc0203e90 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032b0:	0b490593          	addi	a1,s2,180
ffffffffc02032b4:	463d                	li	a2,15
ffffffffc02032b6:	8526                	mv	a0,s1
ffffffffc02032b8:	3eb000ef          	jal	ra,ffffffffc0203ea2 <memcpy>
ffffffffc02032bc:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032be:	85ce                	mv	a1,s3
ffffffffc02032c0:	00002517          	auipc	a0,0x2
ffffffffc02032c4:	37050513          	addi	a0,a0,880 # ffffffffc0205630 <default_pmm_manager+0x920>
ffffffffc02032c8:	ecdfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032cc:	85a2                	mv	a1,s0
ffffffffc02032ce:	00002517          	auipc	a0,0x2
ffffffffc02032d2:	38a50513          	addi	a0,a0,906 # ffffffffc0205658 <default_pmm_manager+0x948>
ffffffffc02032d6:	ebffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032da:	00002517          	auipc	a0,0x2
ffffffffc02032de:	38e50513          	addi	a0,a0,910 # ffffffffc0205668 <default_pmm_manager+0x958>
ffffffffc02032e2:	eb3fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032e6:	70a2                	ld	ra,40(sp)
ffffffffc02032e8:	7402                	ld	s0,32(sp)
ffffffffc02032ea:	64e2                	ld	s1,24(sp)
ffffffffc02032ec:	6942                	ld	s2,16(sp)
ffffffffc02032ee:	69a2                	ld	s3,8(sp)
ffffffffc02032f0:	4501                	li	a0,0
ffffffffc02032f2:	6145                	addi	sp,sp,48
ffffffffc02032f4:	8082                	ret

ffffffffc02032f6 <proc_run>:
{
ffffffffc02032f6:	7179                	addi	sp,sp,-48
ffffffffc02032f8:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02032fa:	0000a917          	auipc	s2,0xa
ffffffffc02032fe:	1d690913          	addi	s2,s2,470 # ffffffffc020d4d0 <current>
{
ffffffffc0203302:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203304:	00093483          	ld	s1,0(s2)
{
ffffffffc0203308:	f406                	sd	ra,40(sp)
ffffffffc020330a:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc020330c:	02a48963          	beq	s1,a0,ffffffffc020333e <proc_run+0x48>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203310:	100027f3          	csrr	a5,sstatus
ffffffffc0203314:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203316:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203318:	e3a1                	bnez	a5,ffffffffc0203358 <proc_run+0x62>
            lsatp(proc->pgdir); 
ffffffffc020331a:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020331c:	80000737          	lui	a4,0x80000
            current = proc;
ffffffffc0203320:	00a93023          	sd	a0,0(s2)
ffffffffc0203324:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203328:	8fd9                	or	a5,a5,a4
ffffffffc020332a:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc020332e:	03050593          	addi	a1,a0,48
ffffffffc0203332:	03048513          	addi	a0,s1,48
ffffffffc0203336:	584000ef          	jal	ra,ffffffffc02038ba <switch_to>
    if (flag) {
ffffffffc020333a:	00099863          	bnez	s3,ffffffffc020334a <proc_run+0x54>
}
ffffffffc020333e:	70a2                	ld	ra,40(sp)
ffffffffc0203340:	7482                	ld	s1,32(sp)
ffffffffc0203342:	6962                	ld	s2,24(sp)
ffffffffc0203344:	69c2                	ld	s3,16(sp)
ffffffffc0203346:	6145                	addi	sp,sp,48
ffffffffc0203348:	8082                	ret
ffffffffc020334a:	70a2                	ld	ra,40(sp)
ffffffffc020334c:	7482                	ld	s1,32(sp)
ffffffffc020334e:	6962                	ld	s2,24(sp)
ffffffffc0203350:	69c2                	ld	s3,16(sp)
ffffffffc0203352:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203354:	dd6fd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc0203358:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020335a:	dd6fd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc020335e:	6522                	ld	a0,8(sp)
ffffffffc0203360:	4985                	li	s3,1
ffffffffc0203362:	bf65                	j	ffffffffc020331a <proc_run+0x24>

ffffffffc0203364 <do_fork>:
{
ffffffffc0203364:	7179                	addi	sp,sp,-48
ffffffffc0203366:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203368:	0000a497          	auipc	s1,0xa
ffffffffc020336c:	18048493          	addi	s1,s1,384 # ffffffffc020d4e8 <nr_process>
ffffffffc0203370:	4098                	lw	a4,0(s1)
{
ffffffffc0203372:	f406                	sd	ra,40(sp)
ffffffffc0203374:	f022                	sd	s0,32(sp)
ffffffffc0203376:	e84a                	sd	s2,16(sp)
ffffffffc0203378:	e44e                	sd	s3,8(sp)
ffffffffc020337a:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020337c:	6785                	lui	a5,0x1
ffffffffc020337e:	22f75063          	bge	a4,a5,ffffffffc020359e <do_fork+0x23a>
ffffffffc0203382:	892e                	mv	s2,a1
ffffffffc0203384:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203386:	e8fff0ef          	jal	ra,ffffffffc0203214 <alloc_proc>
ffffffffc020338a:	89aa                	mv	s3,a0
ffffffffc020338c:	20050e63          	beqz	a0,ffffffffc02035a8 <do_fork+0x244>
    proc->parent = current;
ffffffffc0203390:	0000aa17          	auipc	s4,0xa
ffffffffc0203394:	140a0a13          	addi	s4,s4,320 # ffffffffc020d4d0 <current>
ffffffffc0203398:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020339c:	4509                	li	a0,2
    proc->parent = current;
ffffffffc020339e:	02f9b023          	sd	a5,32(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02033a2:	8fbfe0ef          	jal	ra,ffffffffc0201c9c <alloc_pages>
    if (page != NULL)
ffffffffc02033a6:	1e050763          	beqz	a0,ffffffffc0203594 <do_fork+0x230>
    return page - pages + nbase;
ffffffffc02033aa:	0000a697          	auipc	a3,0xa
ffffffffc02033ae:	10e6b683          	ld	a3,270(a3) # ffffffffc020d4b8 <pages>
ffffffffc02033b2:	40d506b3          	sub	a3,a0,a3
ffffffffc02033b6:	8699                	srai	a3,a3,0x6
ffffffffc02033b8:	00002517          	auipc	a0,0x2
ffffffffc02033bc:	67053503          	ld	a0,1648(a0) # ffffffffc0205a28 <nbase>
ffffffffc02033c0:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033c2:	00c69793          	slli	a5,a3,0xc
ffffffffc02033c6:	83b1                	srli	a5,a5,0xc
ffffffffc02033c8:	0000a717          	auipc	a4,0xa
ffffffffc02033cc:	0e873703          	ld	a4,232(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033d0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033d2:	1ee7fd63          	bgeu	a5,a4,ffffffffc02035cc <do_fork+0x268>
    assert(current->mm == NULL);
ffffffffc02033d6:	000a3783          	ld	a5,0(s4)
ffffffffc02033da:	0000a717          	auipc	a4,0xa
ffffffffc02033de:	0ee73703          	ld	a4,238(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02033e2:	96ba                	add	a3,a3,a4
ffffffffc02033e4:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033e6:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02033ea:	1c079163          	bnez	a5,ffffffffc02035ac <do_fork+0x248>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033ee:	6789                	lui	a5,0x2
ffffffffc02033f0:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033f4:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033f6:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033f8:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc02033fc:	87b6                	mv	a5,a3
ffffffffc02033fe:	12040893          	addi	a7,s0,288
ffffffffc0203402:	00063803          	ld	a6,0(a2)
ffffffffc0203406:	6608                	ld	a0,8(a2)
ffffffffc0203408:	6a0c                	ld	a1,16(a2)
ffffffffc020340a:	6e18                	ld	a4,24(a2)
ffffffffc020340c:	0107b023          	sd	a6,0(a5)
ffffffffc0203410:	e788                	sd	a0,8(a5)
ffffffffc0203412:	eb8c                	sd	a1,16(a5)
ffffffffc0203414:	ef98                	sd	a4,24(a5)
ffffffffc0203416:	02060613          	addi	a2,a2,32
ffffffffc020341a:	02078793          	addi	a5,a5,32
ffffffffc020341e:	ff1612e3          	bne	a2,a7,ffffffffc0203402 <do_fork+0x9e>
    proc->tf->gpr.a0 = 0;
ffffffffc0203422:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203426:	12090563          	beqz	s2,ffffffffc0203550 <do_fork+0x1ec>
ffffffffc020342a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020342e:	00000797          	auipc	a5,0x0
ffffffffc0203432:	e4878793          	addi	a5,a5,-440 # ffffffffc0203276 <forkret>
ffffffffc0203436:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020343a:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020343e:	100027f3          	csrr	a5,sstatus
ffffffffc0203442:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203444:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203446:	12079663          	bnez	a5,ffffffffc0203572 <do_fork+0x20e>
    if (++last_pid >= MAX_PID)
ffffffffc020344a:	00006817          	auipc	a6,0x6
ffffffffc020344e:	bde80813          	addi	a6,a6,-1058 # ffffffffc0209028 <last_pid.1>
ffffffffc0203452:	00082783          	lw	a5,0(a6)
ffffffffc0203456:	6709                	lui	a4,0x2
ffffffffc0203458:	0017851b          	addiw	a0,a5,1
ffffffffc020345c:	00a82023          	sw	a0,0(a6)
ffffffffc0203460:	08e55163          	bge	a0,a4,ffffffffc02034e2 <do_fork+0x17e>
    if (last_pid >= next_safe)
ffffffffc0203464:	00006317          	auipc	t1,0x6
ffffffffc0203468:	bc830313          	addi	t1,t1,-1080 # ffffffffc020902c <next_safe.0>
ffffffffc020346c:	00032783          	lw	a5,0(t1)
ffffffffc0203470:	0000a417          	auipc	s0,0xa
ffffffffc0203474:	fe840413          	addi	s0,s0,-24 # ffffffffc020d458 <proc_list>
ffffffffc0203478:	06f55d63          	bge	a0,a5,ffffffffc02034f2 <do_fork+0x18e>
        proc->pid = get_pid(); // 获取唯一PID
ffffffffc020347c:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203480:	45a9                	li	a1,10
ffffffffc0203482:	2501                	sext.w	a0,a0
ffffffffc0203484:	566000ef          	jal	ra,ffffffffc02039ea <hash32>
ffffffffc0203488:	02051793          	slli	a5,a0,0x20
ffffffffc020348c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203490:	00006797          	auipc	a5,0x6
ffffffffc0203494:	fb878793          	addi	a5,a5,-72 # ffffffffc0209448 <hash_list>
ffffffffc0203498:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020349a:	6510                	ld	a2,8(a0)
ffffffffc020349c:	0d898793          	addi	a5,s3,216
ffffffffc02034a0:	6414                	ld	a3,8(s0)
        nr_process++;          // 进程数加1
ffffffffc02034a2:	4098                	lw	a4,0(s1)
    prev->next = next->prev = elm;
ffffffffc02034a4:	e21c                	sd	a5,0(a2)
ffffffffc02034a6:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02034a8:	0ec9b023          	sd	a2,224(s3)
        list_add(&proc_list, &(proc->list_link)); // 插入进程链表
ffffffffc02034ac:	0c898793          	addi	a5,s3,200
    elm->prev = prev;
ffffffffc02034b0:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc02034b4:	e29c                	sd	a5,0(a3)
        nr_process++;          // 进程数加1
ffffffffc02034b6:	2705                	addiw	a4,a4,1
ffffffffc02034b8:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02034ba:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc02034be:	0c89b423          	sd	s0,200(s3)
ffffffffc02034c2:	c098                	sw	a4,0(s1)
    if (flag) {
ffffffffc02034c4:	0a091b63          	bnez	s2,ffffffffc020357a <do_fork+0x216>
    wakeup_proc(proc);
ffffffffc02034c8:	854e                	mv	a0,s3
ffffffffc02034ca:	45a000ef          	jal	ra,ffffffffc0203924 <wakeup_proc>
    ret = proc->pid;
ffffffffc02034ce:	0049a503          	lw	a0,4(s3)
}
ffffffffc02034d2:	70a2                	ld	ra,40(sp)
ffffffffc02034d4:	7402                	ld	s0,32(sp)
ffffffffc02034d6:	64e2                	ld	s1,24(sp)
ffffffffc02034d8:	6942                	ld	s2,16(sp)
ffffffffc02034da:	69a2                	ld	s3,8(sp)
ffffffffc02034dc:	6a02                	ld	s4,0(sp)
ffffffffc02034de:	6145                	addi	sp,sp,48
ffffffffc02034e0:	8082                	ret
        last_pid = 1;
ffffffffc02034e2:	4785                	li	a5,1
ffffffffc02034e4:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02034e8:	4505                	li	a0,1
ffffffffc02034ea:	00006317          	auipc	t1,0x6
ffffffffc02034ee:	b4230313          	addi	t1,t1,-1214 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc02034f2:	0000a417          	auipc	s0,0xa
ffffffffc02034f6:	f6640413          	addi	s0,s0,-154 # ffffffffc020d458 <proc_list>
ffffffffc02034fa:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02034fe:	6789                	lui	a5,0x2
ffffffffc0203500:	00f32023          	sw	a5,0(t1)
ffffffffc0203504:	86aa                	mv	a3,a0
ffffffffc0203506:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203508:	6e89                	lui	t4,0x2
ffffffffc020350a:	088e0063          	beq	t3,s0,ffffffffc020358a <do_fork+0x226>
ffffffffc020350e:	88ae                	mv	a7,a1
ffffffffc0203510:	87f2                	mv	a5,t3
ffffffffc0203512:	6609                	lui	a2,0x2
ffffffffc0203514:	a811                	j	ffffffffc0203528 <do_fork+0x1c4>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203516:	00e6d663          	bge	a3,a4,ffffffffc0203522 <do_fork+0x1be>
ffffffffc020351a:	00c75463          	bge	a4,a2,ffffffffc0203522 <do_fork+0x1be>
ffffffffc020351e:	863a                	mv	a2,a4
ffffffffc0203520:	4885                	li	a7,1
ffffffffc0203522:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203524:	00878d63          	beq	a5,s0,ffffffffc020353e <do_fork+0x1da>
            if (proc->pid == last_pid)
ffffffffc0203528:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc020352c:	fed715e3          	bne	a4,a3,ffffffffc0203516 <do_fork+0x1b2>
                if (++last_pid >= next_safe)
ffffffffc0203530:	2685                	addiw	a3,a3,1
ffffffffc0203532:	04c6d763          	bge	a3,a2,ffffffffc0203580 <do_fork+0x21c>
ffffffffc0203536:	679c                	ld	a5,8(a5)
ffffffffc0203538:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020353a:	fe8797e3          	bne	a5,s0,ffffffffc0203528 <do_fork+0x1c4>
ffffffffc020353e:	c581                	beqz	a1,ffffffffc0203546 <do_fork+0x1e2>
ffffffffc0203540:	00d82023          	sw	a3,0(a6)
ffffffffc0203544:	8536                	mv	a0,a3
ffffffffc0203546:	f2088be3          	beqz	a7,ffffffffc020347c <do_fork+0x118>
ffffffffc020354a:	00c32023          	sw	a2,0(t1)
ffffffffc020354e:	b73d                	j	ffffffffc020347c <do_fork+0x118>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203550:	8936                	mv	s2,a3
ffffffffc0203552:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203556:	00000797          	auipc	a5,0x0
ffffffffc020355a:	d2078793          	addi	a5,a5,-736 # ffffffffc0203276 <forkret>
ffffffffc020355e:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203562:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203566:	100027f3          	csrr	a5,sstatus
ffffffffc020356a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020356c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020356e:	ec078ee3          	beqz	a5,ffffffffc020344a <do_fork+0xe6>
        intr_disable();
ffffffffc0203572:	bbefd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0203576:	4905                	li	s2,1
ffffffffc0203578:	bdc9                	j	ffffffffc020344a <do_fork+0xe6>
        intr_enable();
ffffffffc020357a:	bb0fd0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020357e:	b7a9                	j	ffffffffc02034c8 <do_fork+0x164>
                    if (last_pid >= MAX_PID)
ffffffffc0203580:	01d6c363          	blt	a3,t4,ffffffffc0203586 <do_fork+0x222>
                        last_pid = 1;
ffffffffc0203584:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203586:	4585                	li	a1,1
ffffffffc0203588:	b749                	j	ffffffffc020350a <do_fork+0x1a6>
ffffffffc020358a:	cd81                	beqz	a1,ffffffffc02035a2 <do_fork+0x23e>
ffffffffc020358c:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0203590:	8536                	mv	a0,a3
ffffffffc0203592:	b5ed                	j	ffffffffc020347c <do_fork+0x118>
    kfree(proc);
ffffffffc0203594:	854e                	mv	a0,s3
ffffffffc0203596:	dd8fe0ef          	jal	ra,ffffffffc0201b6e <kfree>
    ret = -E_NO_MEM;
ffffffffc020359a:	5571                	li	a0,-4
    goto fork_out;
ffffffffc020359c:	bf1d                	j	ffffffffc02034d2 <do_fork+0x16e>
    int ret = -E_NO_FREE_PROC;
ffffffffc020359e:	556d                	li	a0,-5
ffffffffc02035a0:	bf0d                	j	ffffffffc02034d2 <do_fork+0x16e>
    return last_pid;
ffffffffc02035a2:	00082503          	lw	a0,0(a6)
ffffffffc02035a6:	bdd9                	j	ffffffffc020347c <do_fork+0x118>
    ret = -E_NO_MEM;
ffffffffc02035a8:	5571                	li	a0,-4
    return ret;
ffffffffc02035aa:	b725                	j	ffffffffc02034d2 <do_fork+0x16e>
    assert(current->mm == NULL);
ffffffffc02035ac:	00002697          	auipc	a3,0x2
ffffffffc02035b0:	0dc68693          	addi	a3,a3,220 # ffffffffc0205688 <default_pmm_manager+0x978>
ffffffffc02035b4:	00001617          	auipc	a2,0x1
ffffffffc02035b8:	3ac60613          	addi	a2,a2,940 # ffffffffc0204960 <commands+0x818>
ffffffffc02035bc:	12400593          	li	a1,292
ffffffffc02035c0:	00002517          	auipc	a0,0x2
ffffffffc02035c4:	0e050513          	addi	a0,a0,224 # ffffffffc02056a0 <default_pmm_manager+0x990>
ffffffffc02035c8:	e93fc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02035cc:	00001617          	auipc	a2,0x1
ffffffffc02035d0:	77c60613          	addi	a2,a2,1916 # ffffffffc0204d48 <default_pmm_manager+0x38>
ffffffffc02035d4:	07100593          	li	a1,113
ffffffffc02035d8:	00001517          	auipc	a0,0x1
ffffffffc02035dc:	79850513          	addi	a0,a0,1944 # ffffffffc0204d70 <default_pmm_manager+0x60>
ffffffffc02035e0:	e7bfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035e4 <kernel_thread>:
{
ffffffffc02035e4:	7129                	addi	sp,sp,-320
ffffffffc02035e6:	fa22                	sd	s0,304(sp)
ffffffffc02035e8:	f626                	sd	s1,296(sp)
ffffffffc02035ea:	f24a                	sd	s2,288(sp)
ffffffffc02035ec:	84ae                	mv	s1,a1
ffffffffc02035ee:	892a                	mv	s2,a0
ffffffffc02035f0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035f2:	4581                	li	a1,0
ffffffffc02035f4:	12000613          	li	a2,288
ffffffffc02035f8:	850a                	mv	a0,sp
{
ffffffffc02035fa:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035fc:	095000ef          	jal	ra,ffffffffc0203e90 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0203600:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0203602:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203604:	100027f3          	csrr	a5,sstatus
ffffffffc0203608:	edd7f793          	andi	a5,a5,-291
ffffffffc020360c:	1207e793          	ori	a5,a5,288
ffffffffc0203610:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203612:	860a                	mv	a2,sp
ffffffffc0203614:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203618:	00000797          	auipc	a5,0x0
ffffffffc020361c:	bf478793          	addi	a5,a5,-1036 # ffffffffc020320c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203620:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203622:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203624:	d41ff0ef          	jal	ra,ffffffffc0203364 <do_fork>
}
ffffffffc0203628:	70f2                	ld	ra,312(sp)
ffffffffc020362a:	7452                	ld	s0,304(sp)
ffffffffc020362c:	74b2                	ld	s1,296(sp)
ffffffffc020362e:	7912                	ld	s2,288(sp)
ffffffffc0203630:	6131                	addi	sp,sp,320
ffffffffc0203632:	8082                	ret

ffffffffc0203634 <do_exit>:
{
ffffffffc0203634:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203636:	00002617          	auipc	a2,0x2
ffffffffc020363a:	08260613          	addi	a2,a2,130 # ffffffffc02056b8 <default_pmm_manager+0x9a8>
ffffffffc020363e:	19800593          	li	a1,408
ffffffffc0203642:	00002517          	auipc	a0,0x2
ffffffffc0203646:	05e50513          	addi	a0,a0,94 # ffffffffc02056a0 <default_pmm_manager+0x990>
{
ffffffffc020364a:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020364c:	e0ffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203650 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0203650:	7179                	addi	sp,sp,-48
ffffffffc0203652:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203654:	0000a797          	auipc	a5,0xa
ffffffffc0203658:	e0478793          	addi	a5,a5,-508 # ffffffffc020d458 <proc_list>
ffffffffc020365c:	f406                	sd	ra,40(sp)
ffffffffc020365e:	f022                	sd	s0,32(sp)
ffffffffc0203660:	e84a                	sd	s2,16(sp)
ffffffffc0203662:	e44e                	sd	s3,8(sp)
ffffffffc0203664:	00006497          	auipc	s1,0x6
ffffffffc0203668:	de448493          	addi	s1,s1,-540 # ffffffffc0209448 <hash_list>
ffffffffc020366c:	e79c                	sd	a5,8(a5)
ffffffffc020366e:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203670:	0000a717          	auipc	a4,0xa
ffffffffc0203674:	dd870713          	addi	a4,a4,-552 # ffffffffc020d448 <name.2>
ffffffffc0203678:	87a6                	mv	a5,s1
ffffffffc020367a:	e79c                	sd	a5,8(a5)
ffffffffc020367c:	e39c                	sd	a5,0(a5)
ffffffffc020367e:	07c1                	addi	a5,a5,16
ffffffffc0203680:	fef71de3          	bne	a4,a5,ffffffffc020367a <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203684:	b91ff0ef          	jal	ra,ffffffffc0203214 <alloc_proc>
ffffffffc0203688:	0000a917          	auipc	s2,0xa
ffffffffc020368c:	e5090913          	addi	s2,s2,-432 # ffffffffc020d4d8 <idleproc>
ffffffffc0203690:	00a93023          	sd	a0,0(s2)
ffffffffc0203694:	18050d63          	beqz	a0,ffffffffc020382e <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203698:	07000513          	li	a0,112
ffffffffc020369c:	c22fe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036a0:	07000613          	li	a2,112
ffffffffc02036a4:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036a6:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036a8:	7e8000ef          	jal	ra,ffffffffc0203e90 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02036ac:	00093503          	ld	a0,0(s2)
ffffffffc02036b0:	85a2                	mv	a1,s0
ffffffffc02036b2:	07000613          	li	a2,112
ffffffffc02036b6:	03050513          	addi	a0,a0,48
ffffffffc02036ba:	001000ef          	jal	ra,ffffffffc0203eba <memcmp>
ffffffffc02036be:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036c0:	453d                	li	a0,15
ffffffffc02036c2:	bfcfe0ef          	jal	ra,ffffffffc0201abe <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036c6:	463d                	li	a2,15
ffffffffc02036c8:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036ca:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036cc:	7c4000ef          	jal	ra,ffffffffc0203e90 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036d0:	00093503          	ld	a0,0(s2)
ffffffffc02036d4:	463d                	li	a2,15
ffffffffc02036d6:	85a2                	mv	a1,s0
ffffffffc02036d8:	0b450513          	addi	a0,a0,180
ffffffffc02036dc:	7de000ef          	jal	ra,ffffffffc0203eba <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036e0:	00093783          	ld	a5,0(s2)
ffffffffc02036e4:	0000a717          	auipc	a4,0xa
ffffffffc02036e8:	dbc73703          	ld	a4,-580(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc02036ec:	77d4                	ld	a3,168(a5)
ffffffffc02036ee:	0ee68463          	beq	a3,a4,ffffffffc02037d6 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036f2:	4709                	li	a4,2
ffffffffc02036f4:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036f6:	00003717          	auipc	a4,0x3
ffffffffc02036fa:	90a70713          	addi	a4,a4,-1782 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036fe:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203702:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203704:	4705                	li	a4,1
ffffffffc0203706:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203708:	4641                	li	a2,16
ffffffffc020370a:	4581                	li	a1,0
ffffffffc020370c:	8522                	mv	a0,s0
ffffffffc020370e:	782000ef          	jal	ra,ffffffffc0203e90 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203712:	463d                	li	a2,15
ffffffffc0203714:	00002597          	auipc	a1,0x2
ffffffffc0203718:	fec58593          	addi	a1,a1,-20 # ffffffffc0205700 <default_pmm_manager+0x9f0>
ffffffffc020371c:	8522                	mv	a0,s0
ffffffffc020371e:	784000ef          	jal	ra,ffffffffc0203ea2 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203722:	0000a717          	auipc	a4,0xa
ffffffffc0203726:	dc670713          	addi	a4,a4,-570 # ffffffffc020d4e8 <nr_process>
ffffffffc020372a:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020372c:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203730:	4601                	li	a2,0
    nr_process++;
ffffffffc0203732:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203734:	00002597          	auipc	a1,0x2
ffffffffc0203738:	fd458593          	addi	a1,a1,-44 # ffffffffc0205708 <default_pmm_manager+0x9f8>
ffffffffc020373c:	00000517          	auipc	a0,0x0
ffffffffc0203740:	b4850513          	addi	a0,a0,-1208 # ffffffffc0203284 <init_main>
    nr_process++;
ffffffffc0203744:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203746:	0000a797          	auipc	a5,0xa
ffffffffc020374a:	d8d7b523          	sd	a3,-630(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020374e:	e97ff0ef          	jal	ra,ffffffffc02035e4 <kernel_thread>
ffffffffc0203752:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203754:	0ea05963          	blez	a0,ffffffffc0203846 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203758:	6789                	lui	a5,0x2
ffffffffc020375a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020375e:	17f9                	addi	a5,a5,-2
ffffffffc0203760:	2501                	sext.w	a0,a0
ffffffffc0203762:	02e7e363          	bltu	a5,a4,ffffffffc0203788 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203766:	45a9                	li	a1,10
ffffffffc0203768:	282000ef          	jal	ra,ffffffffc02039ea <hash32>
ffffffffc020376c:	02051793          	slli	a5,a0,0x20
ffffffffc0203770:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0203774:	96a6                	add	a3,a3,s1
ffffffffc0203776:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0203778:	a029                	j	ffffffffc0203782 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc020377a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc020377e:	0a870563          	beq	a4,s0,ffffffffc0203828 <proc_init+0x1d8>
    return listelm->next;
ffffffffc0203782:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203784:	fef69be3          	bne	a3,a5,ffffffffc020377a <proc_init+0x12a>
    return NULL;
ffffffffc0203788:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020378a:	0b478493          	addi	s1,a5,180
ffffffffc020378e:	4641                	li	a2,16
ffffffffc0203790:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203792:	0000a417          	auipc	s0,0xa
ffffffffc0203796:	d4e40413          	addi	s0,s0,-690 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020379a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020379c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020379e:	6f2000ef          	jal	ra,ffffffffc0203e90 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037a2:	463d                	li	a2,15
ffffffffc02037a4:	00002597          	auipc	a1,0x2
ffffffffc02037a8:	f9458593          	addi	a1,a1,-108 # ffffffffc0205738 <default_pmm_manager+0xa28>
ffffffffc02037ac:	8526                	mv	a0,s1
ffffffffc02037ae:	6f4000ef          	jal	ra,ffffffffc0203ea2 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037b2:	00093783          	ld	a5,0(s2)
ffffffffc02037b6:	c7e1                	beqz	a5,ffffffffc020387e <proc_init+0x22e>
ffffffffc02037b8:	43dc                	lw	a5,4(a5)
ffffffffc02037ba:	e3f1                	bnez	a5,ffffffffc020387e <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037bc:	601c                	ld	a5,0(s0)
ffffffffc02037be:	c3c5                	beqz	a5,ffffffffc020385e <proc_init+0x20e>
ffffffffc02037c0:	43d8                	lw	a4,4(a5)
ffffffffc02037c2:	4785                	li	a5,1
ffffffffc02037c4:	08f71d63          	bne	a4,a5,ffffffffc020385e <proc_init+0x20e>
}
ffffffffc02037c8:	70a2                	ld	ra,40(sp)
ffffffffc02037ca:	7402                	ld	s0,32(sp)
ffffffffc02037cc:	64e2                	ld	s1,24(sp)
ffffffffc02037ce:	6942                	ld	s2,16(sp)
ffffffffc02037d0:	69a2                	ld	s3,8(sp)
ffffffffc02037d2:	6145                	addi	sp,sp,48
ffffffffc02037d4:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02037d6:	73d8                	ld	a4,160(a5)
ffffffffc02037d8:	ff09                	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037da:	f0099ce3          	bnez	s3,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037de:	6394                	ld	a3,0(a5)
ffffffffc02037e0:	577d                	li	a4,-1
ffffffffc02037e2:	1702                	slli	a4,a4,0x20
ffffffffc02037e4:	f0e697e3          	bne	a3,a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037e8:	4798                	lw	a4,8(a5)
ffffffffc02037ea:	f00714e3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037ee:	6b98                	ld	a4,16(a5)
ffffffffc02037f0:	f00711e3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037f4:	4f98                	lw	a4,24(a5)
ffffffffc02037f6:	2701                	sext.w	a4,a4
ffffffffc02037f8:	ee071de3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc02037fc:	7398                	ld	a4,32(a5)
ffffffffc02037fe:	ee071ae3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc0203802:	7798                	ld	a4,40(a5)
ffffffffc0203804:	ee0717e3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
ffffffffc0203808:	0b07a703          	lw	a4,176(a5)
ffffffffc020380c:	8d59                	or	a0,a0,a4
ffffffffc020380e:	0005071b          	sext.w	a4,a0
ffffffffc0203812:	ee0710e3          	bnez	a4,ffffffffc02036f2 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203816:	00002517          	auipc	a0,0x2
ffffffffc020381a:	ed250513          	addi	a0,a0,-302 # ffffffffc02056e8 <default_pmm_manager+0x9d8>
ffffffffc020381e:	977fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203822:	00093783          	ld	a5,0(s2)
ffffffffc0203826:	b5f1                	j	ffffffffc02036f2 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203828:	f2878793          	addi	a5,a5,-216
ffffffffc020382c:	bfb9                	j	ffffffffc020378a <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc020382e:	00002617          	auipc	a2,0x2
ffffffffc0203832:	ea260613          	addi	a2,a2,-350 # ffffffffc02056d0 <default_pmm_manager+0x9c0>
ffffffffc0203836:	1b300593          	li	a1,435
ffffffffc020383a:	00002517          	auipc	a0,0x2
ffffffffc020383e:	e6650513          	addi	a0,a0,-410 # ffffffffc02056a0 <default_pmm_manager+0x990>
ffffffffc0203842:	c19fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc0203846:	00002617          	auipc	a2,0x2
ffffffffc020384a:	ed260613          	addi	a2,a2,-302 # ffffffffc0205718 <default_pmm_manager+0xa08>
ffffffffc020384e:	1d000593          	li	a1,464
ffffffffc0203852:	00002517          	auipc	a0,0x2
ffffffffc0203856:	e4e50513          	addi	a0,a0,-434 # ffffffffc02056a0 <default_pmm_manager+0x990>
ffffffffc020385a:	c01fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020385e:	00002697          	auipc	a3,0x2
ffffffffc0203862:	f0a68693          	addi	a3,a3,-246 # ffffffffc0205768 <default_pmm_manager+0xa58>
ffffffffc0203866:	00001617          	auipc	a2,0x1
ffffffffc020386a:	0fa60613          	addi	a2,a2,250 # ffffffffc0204960 <commands+0x818>
ffffffffc020386e:	1d700593          	li	a1,471
ffffffffc0203872:	00002517          	auipc	a0,0x2
ffffffffc0203876:	e2e50513          	addi	a0,a0,-466 # ffffffffc02056a0 <default_pmm_manager+0x990>
ffffffffc020387a:	be1fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020387e:	00002697          	auipc	a3,0x2
ffffffffc0203882:	ec268693          	addi	a3,a3,-318 # ffffffffc0205740 <default_pmm_manager+0xa30>
ffffffffc0203886:	00001617          	auipc	a2,0x1
ffffffffc020388a:	0da60613          	addi	a2,a2,218 # ffffffffc0204960 <commands+0x818>
ffffffffc020388e:	1d600593          	li	a1,470
ffffffffc0203892:	00002517          	auipc	a0,0x2
ffffffffc0203896:	e0e50513          	addi	a0,a0,-498 # ffffffffc02056a0 <default_pmm_manager+0x990>
ffffffffc020389a:	bc1fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020389e <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020389e:	1141                	addi	sp,sp,-16
ffffffffc02038a0:	e022                	sd	s0,0(sp)
ffffffffc02038a2:	e406                	sd	ra,8(sp)
ffffffffc02038a4:	0000a417          	auipc	s0,0xa
ffffffffc02038a8:	c2c40413          	addi	s0,s0,-980 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038ac:	6018                	ld	a4,0(s0)
ffffffffc02038ae:	4f1c                	lw	a5,24(a4)
ffffffffc02038b0:	2781                	sext.w	a5,a5
ffffffffc02038b2:	dff5                	beqz	a5,ffffffffc02038ae <cpu_idle+0x10>
        {
            schedule();
ffffffffc02038b4:	0a2000ef          	jal	ra,ffffffffc0203956 <schedule>
ffffffffc02038b8:	bfd5                	j	ffffffffc02038ac <cpu_idle+0xe>

ffffffffc02038ba <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02038ba:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02038be:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02038c2:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02038c4:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02038c6:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02038ca:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02038ce:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02038d2:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02038d6:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02038da:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038de:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038e2:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038e6:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038ea:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02038ee:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038f2:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038f6:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038f8:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038fa:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038fe:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203902:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203906:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020390a:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020390e:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203912:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203916:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020391a:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020391e:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203922:	8082                	ret

ffffffffc0203924 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203924:	411c                	lw	a5,0(a0)
ffffffffc0203926:	4705                	li	a4,1
ffffffffc0203928:	37f9                	addiw	a5,a5,-2
ffffffffc020392a:	00f77563          	bgeu	a4,a5,ffffffffc0203934 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc020392e:	4789                	li	a5,2
ffffffffc0203930:	c11c                	sw	a5,0(a0)
ffffffffc0203932:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203934:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203936:	00002697          	auipc	a3,0x2
ffffffffc020393a:	e5a68693          	addi	a3,a3,-422 # ffffffffc0205790 <default_pmm_manager+0xa80>
ffffffffc020393e:	00001617          	auipc	a2,0x1
ffffffffc0203942:	02260613          	addi	a2,a2,34 # ffffffffc0204960 <commands+0x818>
ffffffffc0203946:	45a5                	li	a1,9
ffffffffc0203948:	00002517          	auipc	a0,0x2
ffffffffc020394c:	e8850513          	addi	a0,a0,-376 # ffffffffc02057d0 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203950:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203952:	b09fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203956 <schedule>:
}

void
schedule(void) {
ffffffffc0203956:	1141                	addi	sp,sp,-16
ffffffffc0203958:	e406                	sd	ra,8(sp)
ffffffffc020395a:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020395c:	100027f3          	csrr	a5,sstatus
ffffffffc0203960:	8b89                	andi	a5,a5,2
ffffffffc0203962:	4401                	li	s0,0
ffffffffc0203964:	efbd                	bnez	a5,ffffffffc02039e2 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203966:	0000a897          	auipc	a7,0xa
ffffffffc020396a:	b6a8b883          	ld	a7,-1174(a7) # ffffffffc020d4d0 <current>
ffffffffc020396e:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203972:	0000a517          	auipc	a0,0xa
ffffffffc0203976:	b6653503          	ld	a0,-1178(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc020397a:	04a88e63          	beq	a7,a0,ffffffffc02039d6 <schedule+0x80>
ffffffffc020397e:	0c888693          	addi	a3,a7,200
ffffffffc0203982:	0000a617          	auipc	a2,0xa
ffffffffc0203986:	ad660613          	addi	a2,a2,-1322 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020398a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020398c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020398e:	4809                	li	a6,2
ffffffffc0203990:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203992:	00c78863          	beq	a5,a2,ffffffffc02039a2 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203996:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020399a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020399e:	03070163          	beq	a4,a6,ffffffffc02039c0 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02039a2:	fef697e3          	bne	a3,a5,ffffffffc0203990 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039a6:	ed89                	bnez	a1,ffffffffc02039c0 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02039a8:	451c                	lw	a5,8(a0)
ffffffffc02039aa:	2785                	addiw	a5,a5,1
ffffffffc02039ac:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02039ae:	00a88463          	beq	a7,a0,ffffffffc02039b6 <schedule+0x60>
            proc_run(next);
ffffffffc02039b2:	945ff0ef          	jal	ra,ffffffffc02032f6 <proc_run>
    if (flag) {
ffffffffc02039b6:	e819                	bnez	s0,ffffffffc02039cc <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02039b8:	60a2                	ld	ra,8(sp)
ffffffffc02039ba:	6402                	ld	s0,0(sp)
ffffffffc02039bc:	0141                	addi	sp,sp,16
ffffffffc02039be:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039c0:	4198                	lw	a4,0(a1)
ffffffffc02039c2:	4789                	li	a5,2
ffffffffc02039c4:	fef712e3          	bne	a4,a5,ffffffffc02039a8 <schedule+0x52>
ffffffffc02039c8:	852e                	mv	a0,a1
ffffffffc02039ca:	bff9                	j	ffffffffc02039a8 <schedule+0x52>
}
ffffffffc02039cc:	6402                	ld	s0,0(sp)
ffffffffc02039ce:	60a2                	ld	ra,8(sp)
ffffffffc02039d0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02039d2:	f59fc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039d6:	0000a617          	auipc	a2,0xa
ffffffffc02039da:	a8260613          	addi	a2,a2,-1406 # ffffffffc020d458 <proc_list>
ffffffffc02039de:	86b2                	mv	a3,a2
ffffffffc02039e0:	b76d                	j	ffffffffc020398a <schedule+0x34>
        intr_disable();
ffffffffc02039e2:	f4ffc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc02039e6:	4405                	li	s0,1
ffffffffc02039e8:	bfbd                	j	ffffffffc0203966 <schedule+0x10>

ffffffffc02039ea <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039ea:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039ee:	2785                	addiw	a5,a5,1
ffffffffc02039f0:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039f4:	02000793          	li	a5,32
ffffffffc02039f8:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039fa:	00f5553b          	srlw	a0,a0,a5
ffffffffc02039fe:	8082                	ret

ffffffffc0203a00 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203a00:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a04:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203a06:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a0a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a0c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a10:	f022                	sd	s0,32(sp)
ffffffffc0203a12:	ec26                	sd	s1,24(sp)
ffffffffc0203a14:	e84a                	sd	s2,16(sp)
ffffffffc0203a16:	f406                	sd	ra,40(sp)
ffffffffc0203a18:	e44e                	sd	s3,8(sp)
ffffffffc0203a1a:	84aa                	mv	s1,a0
ffffffffc0203a1c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a1e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203a22:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203a24:	03067e63          	bgeu	a2,a6,ffffffffc0203a60 <printnum+0x60>
ffffffffc0203a28:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a2a:	00805763          	blez	s0,ffffffffc0203a38 <printnum+0x38>
ffffffffc0203a2e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a30:	85ca                	mv	a1,s2
ffffffffc0203a32:	854e                	mv	a0,s3
ffffffffc0203a34:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a36:	fc65                	bnez	s0,ffffffffc0203a2e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a38:	1a02                	slli	s4,s4,0x20
ffffffffc0203a3a:	00002797          	auipc	a5,0x2
ffffffffc0203a3e:	dae78793          	addi	a5,a5,-594 # ffffffffc02057e8 <default_pmm_manager+0xad8>
ffffffffc0203a42:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203a46:	9a3e                	add	s4,s4,a5
}
ffffffffc0203a48:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a4a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203a4e:	70a2                	ld	ra,40(sp)
ffffffffc0203a50:	69a2                	ld	s3,8(sp)
ffffffffc0203a52:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a54:	85ca                	mv	a1,s2
ffffffffc0203a56:	87a6                	mv	a5,s1
}
ffffffffc0203a58:	6942                	ld	s2,16(sp)
ffffffffc0203a5a:	64e2                	ld	s1,24(sp)
ffffffffc0203a5c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a5e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a60:	03065633          	divu	a2,a2,a6
ffffffffc0203a64:	8722                	mv	a4,s0
ffffffffc0203a66:	f9bff0ef          	jal	ra,ffffffffc0203a00 <printnum>
ffffffffc0203a6a:	b7f9                	j	ffffffffc0203a38 <printnum+0x38>

ffffffffc0203a6c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a6c:	7119                	addi	sp,sp,-128
ffffffffc0203a6e:	f4a6                	sd	s1,104(sp)
ffffffffc0203a70:	f0ca                	sd	s2,96(sp)
ffffffffc0203a72:	ecce                	sd	s3,88(sp)
ffffffffc0203a74:	e8d2                	sd	s4,80(sp)
ffffffffc0203a76:	e4d6                	sd	s5,72(sp)
ffffffffc0203a78:	e0da                	sd	s6,64(sp)
ffffffffc0203a7a:	fc5e                	sd	s7,56(sp)
ffffffffc0203a7c:	f06a                	sd	s10,32(sp)
ffffffffc0203a7e:	fc86                	sd	ra,120(sp)
ffffffffc0203a80:	f8a2                	sd	s0,112(sp)
ffffffffc0203a82:	f862                	sd	s8,48(sp)
ffffffffc0203a84:	f466                	sd	s9,40(sp)
ffffffffc0203a86:	ec6e                	sd	s11,24(sp)
ffffffffc0203a88:	892a                	mv	s2,a0
ffffffffc0203a8a:	84ae                	mv	s1,a1
ffffffffc0203a8c:	8d32                	mv	s10,a2
ffffffffc0203a8e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a90:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a94:	5b7d                	li	s6,-1
ffffffffc0203a96:	00002a97          	auipc	s5,0x2
ffffffffc0203a9a:	d7ea8a93          	addi	s5,s5,-642 # ffffffffc0205814 <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a9e:	00002b97          	auipc	s7,0x2
ffffffffc0203aa2:	f52b8b93          	addi	s7,s7,-174 # ffffffffc02059f0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aa6:	000d4503          	lbu	a0,0(s10)
ffffffffc0203aaa:	001d0413          	addi	s0,s10,1
ffffffffc0203aae:	01350a63          	beq	a0,s3,ffffffffc0203ac2 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203ab2:	c121                	beqz	a0,ffffffffc0203af2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203ab4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ab6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ab8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aba:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203abe:	ff351ae3          	bne	a0,s3,ffffffffc0203ab2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ac2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203ac6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203aca:	4c81                	li	s9,0
ffffffffc0203acc:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203ace:	5c7d                	li	s8,-1
ffffffffc0203ad0:	5dfd                	li	s11,-1
ffffffffc0203ad2:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203ad6:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ad8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203adc:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ae0:	00140d13          	addi	s10,s0,1
ffffffffc0203ae4:	04b56263          	bltu	a0,a1,ffffffffc0203b28 <vprintfmt+0xbc>
ffffffffc0203ae8:	058a                	slli	a1,a1,0x2
ffffffffc0203aea:	95d6                	add	a1,a1,s5
ffffffffc0203aec:	4194                	lw	a3,0(a1)
ffffffffc0203aee:	96d6                	add	a3,a3,s5
ffffffffc0203af0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203af2:	70e6                	ld	ra,120(sp)
ffffffffc0203af4:	7446                	ld	s0,112(sp)
ffffffffc0203af6:	74a6                	ld	s1,104(sp)
ffffffffc0203af8:	7906                	ld	s2,96(sp)
ffffffffc0203afa:	69e6                	ld	s3,88(sp)
ffffffffc0203afc:	6a46                	ld	s4,80(sp)
ffffffffc0203afe:	6aa6                	ld	s5,72(sp)
ffffffffc0203b00:	6b06                	ld	s6,64(sp)
ffffffffc0203b02:	7be2                	ld	s7,56(sp)
ffffffffc0203b04:	7c42                	ld	s8,48(sp)
ffffffffc0203b06:	7ca2                	ld	s9,40(sp)
ffffffffc0203b08:	7d02                	ld	s10,32(sp)
ffffffffc0203b0a:	6de2                	ld	s11,24(sp)
ffffffffc0203b0c:	6109                	addi	sp,sp,128
ffffffffc0203b0e:	8082                	ret
            padc = '0';
ffffffffc0203b10:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203b12:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b16:	846a                	mv	s0,s10
ffffffffc0203b18:	00140d13          	addi	s10,s0,1
ffffffffc0203b1c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b20:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b24:	fcb572e3          	bgeu	a0,a1,ffffffffc0203ae8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203b28:	85a6                	mv	a1,s1
ffffffffc0203b2a:	02500513          	li	a0,37
ffffffffc0203b2e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203b30:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203b34:	8d22                	mv	s10,s0
ffffffffc0203b36:	f73788e3          	beq	a5,s3,ffffffffc0203aa6 <vprintfmt+0x3a>
ffffffffc0203b3a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203b3e:	1d7d                	addi	s10,s10,-1
ffffffffc0203b40:	ff379de3          	bne	a5,s3,ffffffffc0203b3a <vprintfmt+0xce>
ffffffffc0203b44:	b78d                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203b46:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203b4a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b4e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203b50:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b54:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b58:	02d86463          	bltu	a6,a3,ffffffffc0203b80 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b5c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b60:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b64:	0186873b          	addw	a4,a3,s8
ffffffffc0203b68:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b6c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b6e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b72:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b74:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b78:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b7c:	fed870e3          	bgeu	a6,a3,ffffffffc0203b5c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b80:	f40ddce3          	bgez	s11,ffffffffc0203ad8 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b84:	8de2                	mv	s11,s8
ffffffffc0203b86:	5c7d                	li	s8,-1
ffffffffc0203b88:	bf81                	j	ffffffffc0203ad8 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b8a:	fffdc693          	not	a3,s11
ffffffffc0203b8e:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b90:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b94:	00144603          	lbu	a2,1(s0)
ffffffffc0203b98:	2d81                	sext.w	s11,s11
ffffffffc0203b9a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b9c:	bf35                	j	ffffffffc0203ad8 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b9e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203ba6:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba8:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203baa:	bfd9                	j	ffffffffc0203b80 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203bac:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bae:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bb2:	01174463          	blt	a4,a7,ffffffffc0203bba <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203bb6:	1a088e63          	beqz	a7,ffffffffc0203d72 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203bba:	000a3603          	ld	a2,0(s4)
ffffffffc0203bbe:	46c1                	li	a3,16
ffffffffc0203bc0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203bc2:	2781                	sext.w	a5,a5
ffffffffc0203bc4:	876e                	mv	a4,s11
ffffffffc0203bc6:	85a6                	mv	a1,s1
ffffffffc0203bc8:	854a                	mv	a0,s2
ffffffffc0203bca:	e37ff0ef          	jal	ra,ffffffffc0203a00 <printnum>
            break;
ffffffffc0203bce:	bde1                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203bd0:	000a2503          	lw	a0,0(s4)
ffffffffc0203bd4:	85a6                	mv	a1,s1
ffffffffc0203bd6:	0a21                	addi	s4,s4,8
ffffffffc0203bd8:	9902                	jalr	s2
            break;
ffffffffc0203bda:	b5f1                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203bdc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bde:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203be2:	01174463          	blt	a4,a7,ffffffffc0203bea <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203be6:	18088163          	beqz	a7,ffffffffc0203d68 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203bea:	000a3603          	ld	a2,0(s4)
ffffffffc0203bee:	46a9                	li	a3,10
ffffffffc0203bf0:	8a2e                	mv	s4,a1
ffffffffc0203bf2:	bfc1                	j	ffffffffc0203bc2 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bf4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203bf8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bfa:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bfc:	bdf1                	j	ffffffffc0203ad8 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203bfe:	85a6                	mv	a1,s1
ffffffffc0203c00:	02500513          	li	a0,37
ffffffffc0203c04:	9902                	jalr	s2
            break;
ffffffffc0203c06:	b545                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c08:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203c0c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c0e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c10:	b5e1                	j	ffffffffc0203ad8 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203c12:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c14:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c18:	01174463          	blt	a4,a7,ffffffffc0203c20 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203c1c:	14088163          	beqz	a7,ffffffffc0203d5e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203c20:	000a3603          	ld	a2,0(s4)
ffffffffc0203c24:	46a1                	li	a3,8
ffffffffc0203c26:	8a2e                	mv	s4,a1
ffffffffc0203c28:	bf69                	j	ffffffffc0203bc2 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203c2a:	03000513          	li	a0,48
ffffffffc0203c2e:	85a6                	mv	a1,s1
ffffffffc0203c30:	e03e                	sd	a5,0(sp)
ffffffffc0203c32:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203c34:	85a6                	mv	a1,s1
ffffffffc0203c36:	07800513          	li	a0,120
ffffffffc0203c3a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c3c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c3e:	6782                	ld	a5,0(sp)
ffffffffc0203c40:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c42:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203c46:	bfb5                	j	ffffffffc0203bc2 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c48:	000a3403          	ld	s0,0(s4)
ffffffffc0203c4c:	008a0713          	addi	a4,s4,8
ffffffffc0203c50:	e03a                	sd	a4,0(sp)
ffffffffc0203c52:	14040263          	beqz	s0,ffffffffc0203d96 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c56:	0fb05763          	blez	s11,ffffffffc0203d44 <vprintfmt+0x2d8>
ffffffffc0203c5a:	02d00693          	li	a3,45
ffffffffc0203c5e:	0cd79163          	bne	a5,a3,ffffffffc0203d20 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c62:	00044783          	lbu	a5,0(s0)
ffffffffc0203c66:	0007851b          	sext.w	a0,a5
ffffffffc0203c6a:	cf85                	beqz	a5,ffffffffc0203ca2 <vprintfmt+0x236>
ffffffffc0203c6c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c70:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c74:	000c4563          	bltz	s8,ffffffffc0203c7e <vprintfmt+0x212>
ffffffffc0203c78:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c7a:	036c0263          	beq	s8,s6,ffffffffc0203c9e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c7e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c80:	0e0c8e63          	beqz	s9,ffffffffc0203d7c <vprintfmt+0x310>
ffffffffc0203c84:	3781                	addiw	a5,a5,-32
ffffffffc0203c86:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d7c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c8a:	03f00513          	li	a0,63
ffffffffc0203c8e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c90:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c94:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c96:	0a05                	addi	s4,s4,1
ffffffffc0203c98:	0007851b          	sext.w	a0,a5
ffffffffc0203c9c:	ffe1                	bnez	a5,ffffffffc0203c74 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c9e:	01b05963          	blez	s11,ffffffffc0203cb0 <vprintfmt+0x244>
ffffffffc0203ca2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203ca4:	85a6                	mv	a1,s1
ffffffffc0203ca6:	02000513          	li	a0,32
ffffffffc0203caa:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203cac:	fe0d9be3          	bnez	s11,ffffffffc0203ca2 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203cb0:	6a02                	ld	s4,0(sp)
ffffffffc0203cb2:	bbd5                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203cb4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cb6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203cba:	01174463          	blt	a4,a7,ffffffffc0203cc2 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203cbe:	08088d63          	beqz	a7,ffffffffc0203d58 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203cc2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203cc6:	0a044d63          	bltz	s0,ffffffffc0203d80 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203cca:	8622                	mv	a2,s0
ffffffffc0203ccc:	8a66                	mv	s4,s9
ffffffffc0203cce:	46a9                	li	a3,10
ffffffffc0203cd0:	bdcd                	j	ffffffffc0203bc2 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203cd2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cd6:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203cd8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203cda:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203cde:	8fb5                	xor	a5,a5,a3
ffffffffc0203ce0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ce4:	02d74163          	blt	a4,a3,ffffffffc0203d06 <vprintfmt+0x29a>
ffffffffc0203ce8:	00369793          	slli	a5,a3,0x3
ffffffffc0203cec:	97de                	add	a5,a5,s7
ffffffffc0203cee:	639c                	ld	a5,0(a5)
ffffffffc0203cf0:	cb99                	beqz	a5,ffffffffc0203d06 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cf2:	86be                	mv	a3,a5
ffffffffc0203cf4:	00000617          	auipc	a2,0x0
ffffffffc0203cf8:	21460613          	addi	a2,a2,532 # ffffffffc0203f08 <etext+0x2a>
ffffffffc0203cfc:	85a6                	mv	a1,s1
ffffffffc0203cfe:	854a                	mv	a0,s2
ffffffffc0203d00:	0ce000ef          	jal	ra,ffffffffc0203dce <printfmt>
ffffffffc0203d04:	b34d                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203d06:	00002617          	auipc	a2,0x2
ffffffffc0203d0a:	b0260613          	addi	a2,a2,-1278 # ffffffffc0205808 <default_pmm_manager+0xaf8>
ffffffffc0203d0e:	85a6                	mv	a1,s1
ffffffffc0203d10:	854a                	mv	a0,s2
ffffffffc0203d12:	0bc000ef          	jal	ra,ffffffffc0203dce <printfmt>
ffffffffc0203d16:	bb41                	j	ffffffffc0203aa6 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203d18:	00002417          	auipc	s0,0x2
ffffffffc0203d1c:	ae840413          	addi	s0,s0,-1304 # ffffffffc0205800 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d20:	85e2                	mv	a1,s8
ffffffffc0203d22:	8522                	mv	a0,s0
ffffffffc0203d24:	e43e                	sd	a5,8(sp)
ffffffffc0203d26:	0e2000ef          	jal	ra,ffffffffc0203e08 <strnlen>
ffffffffc0203d2a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203d2e:	01b05b63          	blez	s11,ffffffffc0203d44 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203d32:	67a2                	ld	a5,8(sp)
ffffffffc0203d34:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d38:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203d3a:	85a6                	mv	a1,s1
ffffffffc0203d3c:	8552                	mv	a0,s4
ffffffffc0203d3e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d40:	fe0d9ce3          	bnez	s11,ffffffffc0203d38 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d44:	00044783          	lbu	a5,0(s0)
ffffffffc0203d48:	00140a13          	addi	s4,s0,1
ffffffffc0203d4c:	0007851b          	sext.w	a0,a5
ffffffffc0203d50:	d3a5                	beqz	a5,ffffffffc0203cb0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d52:	05e00413          	li	s0,94
ffffffffc0203d56:	bf39                	j	ffffffffc0203c74 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d58:	000a2403          	lw	s0,0(s4)
ffffffffc0203d5c:	b7ad                	j	ffffffffc0203cc6 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d5e:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d62:	46a1                	li	a3,8
ffffffffc0203d64:	8a2e                	mv	s4,a1
ffffffffc0203d66:	bdb1                	j	ffffffffc0203bc2 <vprintfmt+0x156>
ffffffffc0203d68:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d6c:	46a9                	li	a3,10
ffffffffc0203d6e:	8a2e                	mv	s4,a1
ffffffffc0203d70:	bd89                	j	ffffffffc0203bc2 <vprintfmt+0x156>
ffffffffc0203d72:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d76:	46c1                	li	a3,16
ffffffffc0203d78:	8a2e                	mv	s4,a1
ffffffffc0203d7a:	b5a1                	j	ffffffffc0203bc2 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d7c:	9902                	jalr	s2
ffffffffc0203d7e:	bf09                	j	ffffffffc0203c90 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d80:	85a6                	mv	a1,s1
ffffffffc0203d82:	02d00513          	li	a0,45
ffffffffc0203d86:	e03e                	sd	a5,0(sp)
ffffffffc0203d88:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d8a:	6782                	ld	a5,0(sp)
ffffffffc0203d8c:	8a66                	mv	s4,s9
ffffffffc0203d8e:	40800633          	neg	a2,s0
ffffffffc0203d92:	46a9                	li	a3,10
ffffffffc0203d94:	b53d                	j	ffffffffc0203bc2 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d96:	03b05163          	blez	s11,ffffffffc0203db8 <vprintfmt+0x34c>
ffffffffc0203d9a:	02d00693          	li	a3,45
ffffffffc0203d9e:	f6d79de3          	bne	a5,a3,ffffffffc0203d18 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203da2:	00002417          	auipc	s0,0x2
ffffffffc0203da6:	a5e40413          	addi	s0,s0,-1442 # ffffffffc0205800 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203daa:	02800793          	li	a5,40
ffffffffc0203dae:	02800513          	li	a0,40
ffffffffc0203db2:	00140a13          	addi	s4,s0,1
ffffffffc0203db6:	bd6d                	j	ffffffffc0203c70 <vprintfmt+0x204>
ffffffffc0203db8:	00002a17          	auipc	s4,0x2
ffffffffc0203dbc:	a49a0a13          	addi	s4,s4,-1463 # ffffffffc0205801 <default_pmm_manager+0xaf1>
ffffffffc0203dc0:	02800513          	li	a0,40
ffffffffc0203dc4:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203dc8:	05e00413          	li	s0,94
ffffffffc0203dcc:	b565                	j	ffffffffc0203c74 <vprintfmt+0x208>

ffffffffc0203dce <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dce:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203dd0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dd4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203dd6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dd8:	ec06                	sd	ra,24(sp)
ffffffffc0203dda:	f83a                	sd	a4,48(sp)
ffffffffc0203ddc:	fc3e                	sd	a5,56(sp)
ffffffffc0203dde:	e0c2                	sd	a6,64(sp)
ffffffffc0203de0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203de2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203de4:	c89ff0ef          	jal	ra,ffffffffc0203a6c <vprintfmt>
}
ffffffffc0203de8:	60e2                	ld	ra,24(sp)
ffffffffc0203dea:	6161                	addi	sp,sp,80
ffffffffc0203dec:	8082                	ret

ffffffffc0203dee <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203dee:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203df2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203df4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203df6:	cb81                	beqz	a5,ffffffffc0203e06 <strlen+0x18>
        cnt ++;
ffffffffc0203df8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203dfa:	00a707b3          	add	a5,a4,a0
ffffffffc0203dfe:	0007c783          	lbu	a5,0(a5)
ffffffffc0203e02:	fbfd                	bnez	a5,ffffffffc0203df8 <strlen+0xa>
ffffffffc0203e04:	8082                	ret
    }
    return cnt;
}
ffffffffc0203e06:	8082                	ret

ffffffffc0203e08 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e08:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e0a:	e589                	bnez	a1,ffffffffc0203e14 <strnlen+0xc>
ffffffffc0203e0c:	a811                	j	ffffffffc0203e20 <strnlen+0x18>
        cnt ++;
ffffffffc0203e0e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e10:	00f58863          	beq	a1,a5,ffffffffc0203e20 <strnlen+0x18>
ffffffffc0203e14:	00f50733          	add	a4,a0,a5
ffffffffc0203e18:	00074703          	lbu	a4,0(a4)
ffffffffc0203e1c:	fb6d                	bnez	a4,ffffffffc0203e0e <strnlen+0x6>
ffffffffc0203e1e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e20:	852e                	mv	a0,a1
ffffffffc0203e22:	8082                	ret

ffffffffc0203e24 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e24:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e26:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e2a:	0785                	addi	a5,a5,1
ffffffffc0203e2c:	0585                	addi	a1,a1,1
ffffffffc0203e2e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e32:	fb75                	bnez	a4,ffffffffc0203e26 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e34:	8082                	ret

ffffffffc0203e36 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e36:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e3a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e3e:	cb89                	beqz	a5,ffffffffc0203e50 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203e40:	0505                	addi	a0,a0,1
ffffffffc0203e42:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e44:	fee789e3          	beq	a5,a4,ffffffffc0203e36 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e48:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e4c:	9d19                	subw	a0,a0,a4
ffffffffc0203e4e:	8082                	ret
ffffffffc0203e50:	4501                	li	a0,0
ffffffffc0203e52:	bfed                	j	ffffffffc0203e4c <strcmp+0x16>

ffffffffc0203e54 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e54:	c20d                	beqz	a2,ffffffffc0203e76 <strncmp+0x22>
ffffffffc0203e56:	962e                	add	a2,a2,a1
ffffffffc0203e58:	a031                	j	ffffffffc0203e64 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e5a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e5c:	00e79a63          	bne	a5,a4,ffffffffc0203e70 <strncmp+0x1c>
ffffffffc0203e60:	00b60b63          	beq	a2,a1,ffffffffc0203e76 <strncmp+0x22>
ffffffffc0203e64:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e68:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e6a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e6e:	f7f5                	bnez	a5,ffffffffc0203e5a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e70:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e74:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e76:	4501                	li	a0,0
ffffffffc0203e78:	8082                	ret

ffffffffc0203e7a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e7a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e7e:	c799                	beqz	a5,ffffffffc0203e8c <strchr+0x12>
        if (*s == c) {
ffffffffc0203e80:	00f58763          	beq	a1,a5,ffffffffc0203e8e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e84:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e88:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e8a:	fbfd                	bnez	a5,ffffffffc0203e80 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e8c:	4501                	li	a0,0
}
ffffffffc0203e8e:	8082                	ret

ffffffffc0203e90 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e90:	ca01                	beqz	a2,ffffffffc0203ea0 <memset+0x10>
ffffffffc0203e92:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e94:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e96:	0785                	addi	a5,a5,1
ffffffffc0203e98:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e9c:	fec79de3          	bne	a5,a2,ffffffffc0203e96 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203ea0:	8082                	ret

ffffffffc0203ea2 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203ea2:	ca19                	beqz	a2,ffffffffc0203eb8 <memcpy+0x16>
ffffffffc0203ea4:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203ea6:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203ea8:	0005c703          	lbu	a4,0(a1)
ffffffffc0203eac:	0585                	addi	a1,a1,1
ffffffffc0203eae:	0785                	addi	a5,a5,1
ffffffffc0203eb0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203eb4:	fec59ae3          	bne	a1,a2,ffffffffc0203ea8 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203eb8:	8082                	ret

ffffffffc0203eba <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203eba:	c205                	beqz	a2,ffffffffc0203eda <memcmp+0x20>
ffffffffc0203ebc:	962e                	add	a2,a2,a1
ffffffffc0203ebe:	a019                	j	ffffffffc0203ec4 <memcmp+0xa>
ffffffffc0203ec0:	00c58d63          	beq	a1,a2,ffffffffc0203eda <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ec4:	00054783          	lbu	a5,0(a0)
ffffffffc0203ec8:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203ecc:	0505                	addi	a0,a0,1
ffffffffc0203ece:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203ed0:	fee788e3          	beq	a5,a4,ffffffffc0203ec0 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ed4:	40e7853b          	subw	a0,a5,a4
ffffffffc0203ed8:	8082                	ret
    }
    return 0;
ffffffffc0203eda:	4501                	li	a0,0
}
ffffffffc0203edc:	8082                	ret
