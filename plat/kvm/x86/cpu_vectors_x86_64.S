/* SPDX-License-Identifier: ISC */
/*
 * Authors: Dan Williams
 *          Martin Lucina
 *          Costin Lupu <costin.lupu@cs.pub.ro>
 *
 * Copyright (c) 2015-2017 IBM
 * Copyright (c) 2016-2017 Docker, Inc.
 * Copyright (c) 2018, NEC Europe Ltd., NEC Corporation
 *
 * Permission to use, copy, modify, and/or distribute this software
 * for any purpose with or without fee is hereby granted, provided
 * that the above copyright notice and this permission notice appear
 * in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
/* Taken from solo5 */

#include <x86/traps.h>
#include <x86/cfi.h>

#define ENTRY(X)     .global X ; .type X, @function ; X:

.macro PUSH_CALLER_SAVE
	pushq_cfi %rdi
	pushq_cfi %rsi
	pushq_cfi %rdx
	pushq_cfi %rcx
	pushq_cfi %rax
	pushq_cfi %r8
	pushq_cfi %r9
	pushq_cfi %r10
	pushq_cfi %r11
	pushq_cfi %rbx
	pushq_cfi %rbp
	pushq_cfi %r12
	pushq_cfi %r13
	pushq_cfi %r14
	pushq_cfi %r15
.endm

.macro POP_CALLER_SAVE
	popq_cfi %r15
	popq_cfi %r14
	popq_cfi %r13
	popq_cfi %r12
	popq_cfi %rbp
	popq_cfi %rbx
	popq_cfi %r11
	popq_cfi %r10
	popq_cfi %r9
	popq_cfi %r8
	popq_cfi %rax
	popq_cfi %rcx
	popq_cfi %rdx
	popq_cfi %rsi
	popq_cfi %rdi
.endm

.macro TRAP_ENTRY trapname, has_ec
ENTRY(ASM_TRAP_SYM(\trapname))
	.cfi_startproc
	.cfi_signal_frame
.if \has_ec
	/* Error code is pushed on the stack after RIP */
	.cfi_def_cfa_offset 16
.endif
	/* Description of the stack with active IST */
	.cfi_offset cs, 0
	.cfi_offset rflags, 8
	.cfi_offset rsp, 16
	.cfi_offset ss, 24
	cld

.if !\has_ec
	pushq_cfi $0                        /* no error code, pass 0 */
.endif
	PUSH_CALLER_SAVE
	subq $__REGS_PAD_SIZE, %rsp         /* we have some padding */
	.cfi_adjust_cfa_offset __REGS_PAD_SIZE

	movq %rsp, %rdi
	.cfi_rel_offset rdi, 0
	movq __REGS_OFFSETOF_ORIG_RAX(%rsp), %rsi
	.cfi_rel_offset rsi, 8
	call do_\trapname

	addq $__REGS_PAD_SIZE, %rsp         /* we have some padding */
	.cfi_adjust_cfa_offset -__REGS_PAD_SIZE
	POP_CALLER_SAVE
	.cfi_restore rdi
	.cfi_restore rsi
	addq $8, %rsp                       /* discard error code */
	.cfi_adjust_cfa_offset -8

	iretq
	.cfi_endproc
.endm

.macro IRQ_ENTRY irqno
ENTRY(cpu_irq_\irqno)
	.cfi_startproc
	.cfi_signal_frame
	/* Description of the stack with active IST */
	.cfi_offset cs, 0
	.cfi_offset rflags, 8
	.cfi_offset rsp, 16
	.cfi_offset ss, 24
	cld

	pushq_cfi $0                        /* no error code */
	PUSH_CALLER_SAVE
	subq $__REGS_PAD_SIZE, %rsp         /* we have some padding */
	.cfi_adjust_cfa_offset __REGS_PAD_SIZE

	movq %rsp, %rdi
	.cfi_rel_offset rdi, 0
	movq $\irqno, %rsi
	.cfi_rel_offset rsi, 8
	call _ukplat_irq_handle

	addq $__REGS_PAD_SIZE, %rsp         /* we have some padding */
	.cfi_adjust_cfa_offset -__REGS_PAD_SIZE
	POP_CALLER_SAVE
	.cfi_restore rdi
	.cfi_restore rsi
	addq $8, %rsp
	.cfi_adjust_cfa_offset -8

	iretq
	.cfi_endproc
.endm

TRAP_ENTRY divide_error,     0
TRAP_ENTRY debug,            0
TRAP_ENTRY nmi,              0
TRAP_ENTRY int3,             0
TRAP_ENTRY overflow,         0
TRAP_ENTRY bounds,           0
TRAP_ENTRY invalid_op,       0
TRAP_ENTRY no_device,        0
TRAP_ENTRY double_fault,     1
TRAP_ENTRY invalid_tss,      1
TRAP_ENTRY no_segment,       1
TRAP_ENTRY stack_error,      1
TRAP_ENTRY gp_fault,         1
TRAP_ENTRY page_fault,       1
TRAP_ENTRY coproc_error,     0
TRAP_ENTRY alignment_check,  1
TRAP_ENTRY machine_check,    0
TRAP_ENTRY simd_error,       0
TRAP_ENTRY virt_error,       0

IRQ_ENTRY 0
IRQ_ENTRY 1
IRQ_ENTRY 2
IRQ_ENTRY 3
IRQ_ENTRY 4
IRQ_ENTRY 5
IRQ_ENTRY 6
IRQ_ENTRY 7
IRQ_ENTRY 8
IRQ_ENTRY 9
IRQ_ENTRY 10
IRQ_ENTRY 11
IRQ_ENTRY 12
IRQ_ENTRY 13
IRQ_ENTRY 14
IRQ_ENTRY 15
