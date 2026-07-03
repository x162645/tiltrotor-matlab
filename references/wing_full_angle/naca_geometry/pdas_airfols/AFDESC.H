*  'afdesc.h' ...FORTRAN INCLUDE FILE
*                                                                      *
      CHARACTER DESIGC*12, DESIGP*12, PATH*60, TITLE*60
      INTEGER*4 CMBNMR, IAC, IAD, KOUNTX, KREC, MLC, MLD
      REAL*4 A(10), A0, A1, A2, A3, CHD, CLI(10), CMB, CMY, D0, D1, D2
      REAL*4 D3, DX, RC, RK2OK1, RLE, TOC, X(300), XC, XCL, XCU, XL
      REAL*4 XMT, XU, Y, YC, YCL, YCU, YL, YP, YPL, YPU, YPP, YU
      COMMON /AFDESC/ A, A0, A1, A2, A3, CHD, CLI, CMB, CMBNMR, CMY, D0,
     +                D1, D2, D3, DX, IAC, IAD, KOUNTX, KREC, MLC, MLD,
     +                RC, RK2OK1, RLE, TOC, X, XC, XCL, XCU, XL, XMT,
     +                XU, Y, YC, YCL, YCU, YL, YP, YPL, YPU, YPP, YU
      COMMON /AFTEXT/ DESIGC, DESIGP, PATH, TITLE

