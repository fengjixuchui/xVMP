; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=r600-- -mcpu=cypress -verify-machineinstrs < %s | FileCheck -check-prefix=EG %s
; RUN: llc -mtriple=r600-- -mcpu=cayman -verify-machineinstrs < %s | FileCheck -check-prefix=CM %s

; Loosely based on test/CodeGen/{X86,AArch64}/extract-lowbits.ll,
; but with all 64-bit tests, and tests with loads dropped.

; Patterns:
;   a) x &  (1 << nbits) - 1
;   b) x & ~(-1 << nbits)
;   c) x &  (-1 >> (32 - y))
;   d) x << (32 - y) >> (32 - y)
; are equivalent.

; ---------------------------------------------------------------------------- ;
; Pattern a. 32-bit
; ---------------------------------------------------------------------------- ;

define amdgpu_kernel void @bzhi32_a0(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_a0:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_a0:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %onebit = shl i32 1, %numlowbits
  %mask = add nsw i32 %onebit, -1
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_a1_indexzext(i32 %val, i8 zeroext %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_a1_indexzext:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 0, @8, KC0[], KC1[]
; EG-NEXT:    TEX 0 @6
; EG-NEXT:    ALU 4, @9, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T0.X, T1.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    Fetch clause starting at 6:
; EG-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; EG-NEXT:    ALU clause starting at 8:
; EG-NEXT:     MOV * T0.X, 0.0,
; EG-NEXT:    ALU clause starting at 9:
; EG-NEXT:     BFE_INT * T0.W, T0.X, 0.0, literal.x,
; EG-NEXT:    8(1.121039e-44), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT T0.X, KC0[2].Y, 0.0, PV.W,
; EG-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
;
; CM-LABEL: bzhi32_a1_indexzext:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 0, @8, KC0[], KC1[]
; CM-NEXT:    TEX 0 @6
; CM-NEXT:    ALU 4, @9, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T0.X, T1.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    Fetch clause starting at 6:
; CM-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; CM-NEXT:    ALU clause starting at 8:
; CM-NEXT:     MOV * T0.X, 0.0,
; CM-NEXT:    ALU clause starting at 9:
; CM-NEXT:     BFE_INT * T0.W, T0.X, 0.0, literal.x,
; CM-NEXT:    8(1.121039e-44), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T0.X, KC0[2].Y, 0.0, PV.W,
; CM-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
  %conv = zext i8 %numlowbits to i32
  %onebit = shl i32 1, %conv
  %mask = add nsw i32 %onebit, -1
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_a4_commutative(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_a4_commutative:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_a4_commutative:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %onebit = shl i32 1, %numlowbits
  %mask = add nsw i32 %onebit, -1
  %masked = and i32 %val, %mask ; swapped order
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

; ---------------------------------------------------------------------------- ;
; Pattern b. 32-bit
; ---------------------------------------------------------------------------- ;

define amdgpu_kernel void @bzhi32_b0(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_b0:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_b0:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %notmask = shl i32 -1, %numlowbits
  %mask = xor i32 %notmask, -1
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_b1_indexzext(i32 %val, i8 zeroext %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_b1_indexzext:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 0, @8, KC0[], KC1[]
; EG-NEXT:    TEX 0 @6
; EG-NEXT:    ALU 4, @9, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T0.X, T1.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    Fetch clause starting at 6:
; EG-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; EG-NEXT:    ALU clause starting at 8:
; EG-NEXT:     MOV * T0.X, 0.0,
; EG-NEXT:    ALU clause starting at 9:
; EG-NEXT:     BFE_INT * T0.W, T0.X, 0.0, literal.x,
; EG-NEXT:    8(1.121039e-44), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT T0.X, KC0[2].Y, 0.0, PV.W,
; EG-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
;
; CM-LABEL: bzhi32_b1_indexzext:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 0, @8, KC0[], KC1[]
; CM-NEXT:    TEX 0 @6
; CM-NEXT:    ALU 4, @9, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T0.X, T1.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    Fetch clause starting at 6:
; CM-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; CM-NEXT:    ALU clause starting at 8:
; CM-NEXT:     MOV * T0.X, 0.0,
; CM-NEXT:    ALU clause starting at 9:
; CM-NEXT:     BFE_INT * T0.W, T0.X, 0.0, literal.x,
; CM-NEXT:    8(1.121039e-44), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T0.X, KC0[2].Y, 0.0, PV.W,
; CM-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
  %conv = zext i8 %numlowbits to i32
  %notmask = shl i32 -1, %conv
  %mask = xor i32 %notmask, -1
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_b4_commutative(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_b4_commutative:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_b4_commutative:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %notmask = shl i32 -1, %numlowbits
  %mask = xor i32 %notmask, -1
  %masked = and i32 %val, %mask ; swapped order
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

; ---------------------------------------------------------------------------- ;
; Pattern c. 32-bit
; ---------------------------------------------------------------------------- ;

define amdgpu_kernel void @bzhi32_c0(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_c0:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_c0:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %numhighbits = sub i32 32, %numlowbits
  %mask = lshr i32 -1, %numhighbits
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_c1_indexzext(i32 %val, i8 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_c1_indexzext:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 0, @8, KC0[], KC1[]
; EG-NEXT:    TEX 0 @6
; EG-NEXT:    ALU 8, @9, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T0.X, T1.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    Fetch clause starting at 6:
; EG-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; EG-NEXT:    ALU clause starting at 8:
; EG-NEXT:     MOV * T0.X, 0.0,
; EG-NEXT:    ALU clause starting at 9:
; EG-NEXT:     SUB_INT * T0.W, literal.x, T0.X,
; EG-NEXT:    32(4.484155e-44), 0(0.000000e+00)
; EG-NEXT:     AND_INT * T0.W, PV.W, literal.x,
; EG-NEXT:    255(3.573311e-43), 0(0.000000e+00)
; EG-NEXT:     LSHR * T0.W, literal.x, PV.W,
; EG-NEXT:    -1(nan), 0(0.000000e+00)
; EG-NEXT:     AND_INT T0.X, PV.W, KC0[2].Y,
; EG-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
;
; CM-LABEL: bzhi32_c1_indexzext:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 0, @8, KC0[], KC1[]
; CM-NEXT:    TEX 0 @6
; CM-NEXT:    ALU 8, @9, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T0.X, T1.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    Fetch clause starting at 6:
; CM-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; CM-NEXT:    ALU clause starting at 8:
; CM-NEXT:     MOV * T0.X, 0.0,
; CM-NEXT:    ALU clause starting at 9:
; CM-NEXT:     SUB_INT * T0.W, literal.x, T0.X,
; CM-NEXT:    32(4.484155e-44), 0(0.000000e+00)
; CM-NEXT:     AND_INT * T0.W, PV.W, literal.x,
; CM-NEXT:    255(3.573311e-43), 0(0.000000e+00)
; CM-NEXT:     LSHR * T0.W, literal.x, PV.W,
; CM-NEXT:    -1(nan), 0(0.000000e+00)
; CM-NEXT:     AND_INT * T0.X, PV.W, KC0[2].Y,
; CM-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
  %numhighbits = sub i8 32, %numlowbits
  %sh_prom = zext i8 %numhighbits to i32
  %mask = lshr i32 -1, %sh_prom
  %masked = and i32 %mask, %val
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_c4_commutative(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_c4_commutative:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_c4_commutative:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %numhighbits = sub i32 32, %numlowbits
  %mask = lshr i32 -1, %numhighbits
  %masked = and i32 %val, %mask ; swapped order
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

; ---------------------------------------------------------------------------- ;
; Pattern d. 32-bit.
; ---------------------------------------------------------------------------- ;

define amdgpu_kernel void @bzhi32_d0(i32 %val, i32 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_d0:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T1.X, T0.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    ALU clause starting at 4:
; EG-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; EG-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
;
; CM-LABEL: bzhi32_d0:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 2, @4, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T1.X, T0.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    ALU clause starting at 4:
; CM-NEXT:     LSHR * T0.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
; CM-NEXT:     BFE_UINT * T1.X, KC0[2].Y, 0.0, KC0[2].Z,
  %numhighbits = sub i32 32, %numlowbits
  %highbitscleared = shl i32 %val, %numhighbits
  %masked = lshr i32 %highbitscleared, %numhighbits
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}

define amdgpu_kernel void @bzhi32_d1_indexzext(i32 %val, i8 %numlowbits, i32 addrspace(1)* %out) {
; EG-LABEL: bzhi32_d1_indexzext:
; EG:       ; %bb.0:
; EG-NEXT:    ALU 0, @8, KC0[], KC1[]
; EG-NEXT:    TEX 0 @6
; EG-NEXT:    ALU 7, @9, KC0[CB0:0-32], KC1[]
; EG-NEXT:    MEM_RAT_CACHELESS STORE_RAW T0.X, T1.X, 1
; EG-NEXT:    CF_END
; EG-NEXT:    PAD
; EG-NEXT:    Fetch clause starting at 6:
; EG-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; EG-NEXT:    ALU clause starting at 8:
; EG-NEXT:     MOV * T0.X, 0.0,
; EG-NEXT:    ALU clause starting at 9:
; EG-NEXT:     SUB_INT * T0.W, literal.x, T0.X,
; EG-NEXT:    32(4.484155e-44), 0(0.000000e+00)
; EG-NEXT:     AND_INT * T0.W, PV.W, literal.x,
; EG-NEXT:    255(3.573311e-43), 0(0.000000e+00)
; EG-NEXT:     LSHL * T1.W, KC0[2].Y, PV.W,
; EG-NEXT:     LSHR T0.X, PV.W, T0.W,
; EG-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; EG-NEXT:    2(2.802597e-45), 0(0.000000e+00)
;
; CM-LABEL: bzhi32_d1_indexzext:
; CM:       ; %bb.0:
; CM-NEXT:    ALU 0, @8, KC0[], KC1[]
; CM-NEXT:    TEX 0 @6
; CM-NEXT:    ALU 7, @9, KC0[CB0:0-32], KC1[]
; CM-NEXT:    MEM_RAT_CACHELESS STORE_DWORD T0.X, T1.X
; CM-NEXT:    CF_END
; CM-NEXT:    PAD
; CM-NEXT:    Fetch clause starting at 6:
; CM-NEXT:     VTX_READ_8 T0.X, T0.X, 40, #3
; CM-NEXT:    ALU clause starting at 8:
; CM-NEXT:     MOV * T0.X, 0.0,
; CM-NEXT:    ALU clause starting at 9:
; CM-NEXT:     SUB_INT * T0.W, literal.x, T0.X,
; CM-NEXT:    32(4.484155e-44), 0(0.000000e+00)
; CM-NEXT:     AND_INT * T0.W, PV.W, literal.x,
; CM-NEXT:    255(3.573311e-43), 0(0.000000e+00)
; CM-NEXT:     LSHL * T1.W, KC0[2].Y, PV.W,
; CM-NEXT:     LSHR * T0.X, PV.W, T0.W,
; CM-NEXT:     LSHR * T1.X, KC0[2].W, literal.x,
; CM-NEXT:    2(2.802597e-45), 0(0.000000e+00)
  %numhighbits = sub i8 32, %numlowbits
  %sh_prom = zext i8 %numhighbits to i32
  %highbitscleared = shl i32 %val, %sh_prom
  %masked = lshr i32 %highbitscleared, %sh_prom
  store i32 %masked, i32 addrspace(1)* %out
  ret void
}