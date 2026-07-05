CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 AUG 90, 804-865-1725 CCCCCCCCCC
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  TITLE: NACA AIRFOIL ORDINATE GENERATOR
C  NAME:  AIRFOLS 
C  VERSION:  1.00
C  LANGUAGE: FORTRAN 77
C  RELEASE DATE:  31 MARCH 92
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  CHANGES:
C          DWS-02JUN95-INTERPOLATION METHOD IN ROUTINE NTRP REPLACED FROM
C                      CONVENTIONAL 2ND ORDER LAGRANGIAN TO PIECEWISE CUBIC.
C          DWS-30SEP95-AIRFOLS RE-RELEASED AS VERSION 1.0 (airfols-1.00).
C          DWS-01MAR96-MODIFIED SO THAT RATIONAL X-ARRAY VALUES ARE PRODUCED 
C                      FOR DX OF .01, .05, AND .1 (1%, 5%, 10%).
C          DWS-02APR96-PROGRAM STOP MOVED TO ROUTINE ADMIN.
C          DWS-  APR96-AIRFOLS RE-RELEASED AS VERSION 1.01 (airfols-1.01) 
C                      SUPPORTED BY THE NASA TECHNICAL MEMORANDUM.
C 
C 
C  BUILD/EXECUTION SEQUENCES:
C          " Edit ether the file airfols.f or AIRFOLS.FOR to locate in the text
C            the word '*INSTRUCTION*' then follow the specified directions. "
C 
C          COMPUTER: CONVEX / UNIX / CONVEX FORTRAN
C                   fc -72 airfols.f -o airfols
C                   airfols
C 
C          COMPUTER: GATEWAY 2000 PC / DOS / LAHEY FORTRAN
C                   F77L AIRFOLS[.for] /A /NF /NS /NW
C                   OPTLINK AIRFOLS[.obj];
C                   AIRFOLS
C 
C          COMPUTER: IBMPC / DOS / IBM FORTRAN/2
C                   F77 [/laxs] AIRFOLS[.for]     (\FORT\FORTRAN AIRFOLS)
C                   LNK AIRFOLS[.obj]             (\FORT\LINK AIRFOLS;)
C                   AIRFOLS
C 
C          COMPUTER: IRIS / IRIX / IRIS FORTRAN
C                   f77 airfols.f -o airfols
C                   airfols
C 
C          COMPUTER: SUN / SUNOS / SUN FORTRAN
C                   f77 -xl airfols.f -o airfols
C                   airfols
C 
C          COMPUTER: VAX / VMS / VAX FORTRAN
C                   FOR AIRFOLS[.for]
C                   LINK AIRFOLS[.obj]
C                   AIRFOLS :== RUN AIRFOLS[.exe]
C                   AIRFOLS[.exe]
C 
C 
C  OBJECTIVE: AIRFOLS IS THE NACA AIRFOIL ORDINATE GENERATOR.  THIS 
C          COMPUTER PROGRAM IS A PORTABLE, ANSI FORTRAN 77 CODE WITH VERY 
C          LIMITED PLATFORM DEPENDANCIES.  DATA IS ENTERED TO THE SOFTWARE 
C          WITH MENU AND PROMPT DRIVEN INPUT.  OUTPUT CONSIST OF A REPORT 
C          AND A DATA FILE CONTAINING THE NONDIMENSIONAL AND DIMENSIONAL 
C          AIRFOIL ORDINATES AS WELL AS OTHER INPUT AND OUTPUT PARAMETERS.  
C          AIRFOLS IS THE RESULT OF MERGING TWO PREVIOUS EFFORTS REPORTED 
C          IN THE NASA TM'S X-3069 AND X-3284.  THIS PROGRAM RAPIDLY 
C          CALCULATES THE ORDINATES AND SURFACE SLOPE FOR AIRFOILS OF ANY 
C          THICKNESS, THICKNESS DISTRIBUTION, OR CAMBER IN THE DESIGNATED 
C          NACA SERIES.  THE ANALYTICAL DESIGN EQUATIONS FOR BOTH SYMMETRICAL 
C          AND CAMBERED AIRFOILS IN THE NACA 4-DIGIT, MODIFIED 4-DIGIT, 
C          5-DIGIT, MODIFIED 5-DIGIT, 16-SERIES, 6-SERIES, AND 6A-SERIES 
C          AIRFOIL FAMILIES HAVE BEEN IMPLEMENTED.  THE CAMBER LINE 
C          DESIGNATIONS AVAILABLE ARE THE 2-DIGIT, 3-DIGIT, 3-DIGIT REFLEX, 
C          6-SERIES, AND 6A-SERIES.  MANY OF THESE AIRFOIL SHAPES HAVE BEEN 
C          SUCCESSFULLY USED OVER THE YEARS AS WING AND TAIL SECTIONS FOR 
C          GENERAL AVIATION AS WELL AS MILITARY AIRCRAFT.  SOME HAVE BEEN 
C          AND ARE STILL BEING USED AS SECTIONS FOR PROPELLERS AND HELICOPTER 
C          ROTORS.
C 
C 
C  METHOD: THE METHOD USED IN THIS PROGRAM IS BETTER DESRIBED IN DETAIL
C          IN THE AFORE MENTIONED PAPERS AND A PAPER SPECIFICALLY PUB-
C          LISHED TO ACCOMPANY THIS PROGRAM.
C 
C 
C  RESTRICTIONS, ASSUMPTIONS:
C          THE VARIABLES unused AND nouse ARE DUMMY PARAMETERS THAT NEVER
C          ARE ASSIGNED VALUES.
C          '
C 
C 
C  EXIT STATES:
C          AIRFOLS: NORMAL TERMINATION, PROGRAM COMPLETE.
C 
C 
C  I/O UNITS:
C          INPUT:
C                   NONE
C 
C          OUTPUT: 
C                   TAPE1:   ' 
C 
C                   TAPE2:   ' 
C 
C          SCRATCH:
C                   TAPE3:   ' 
C 
C                   TAPE9:   ' 
C 
C          OTHERS: 
C                   NONE
C 
C 
C  INCLUDE FILES:
C          NONE 
C 
C 
C  LIBRARIES:
C          NONE 
C 
C 
C  ENTRY POINTS: 
C          AIRFOLS: MAIN AND ONLY ENTRY POINT TO PROGRAM.
C 
C 
C  FUNCTIONS:
C          NONE 
C 
C 
C  SUBROUTINES:
C          NONE 
C 
C 
C  PROCEDURE CROSS-REFERENCES: 
C          NONE 
C 
C 
C  COMMON BLOCKS:
C          NONE 
C 
C 
C  COMMON BLOCK CROSS-REFERENCES:
C          NONE 
C 
C 
C  COMMON BLOCK VARIABLES: 
C          NONE 
C 
C 
C  NAMELISTS:
C          NONE 
C 
C 
C  NAMELIST VARIABLES: 
C          NONE 
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  ACKNOWLEDGEMENTS:
C          ENGINEERING SUPPORT:
C                   Technological information provided 1990-1992 by;
C                   Charles L. Ladson
C                   NASA / Langley Research Center
C                   Hampton, Va.  23665
C
C          ORIGINATORS:
C                   Initial programs developed 1974-1975 by;
C                   Charles L. Ladson and Cuyler W. Brooks, Jr.
C                   NASA / Langley Research Center
C                   Hampton, Va.  23665
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
************************************************************************
      PROGRAM AIRFOL
************************************************************************ 
*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION
************************************************************************ 
*  TO PRODUCE EXECUTABLE BINARIES FOR THE DESIRED PLATFORM, CHOOSE ONE 
*  OF THE NEXT LINES OF CODE CONTAINING A PARAMETER STATEMENT WHICH 
*  DESCRIBES THE APPLICABLE PLATFORM THEN UNCOMMENT ONLY THIS LINE TO 
*  ACTIVATE THAT DEVICE.  THIS MUST BE PERFORMED BEFORE COMPILATION.
************************************************************************ 
*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION*INSTRUCTION
************************************************************************ 
      CHARACTER PDV*10
* 
c     PARAMETER (PDV= 'CNVXC2')
      PARAMETER (PDV= 'IBMPC') 
c     PARAMETER (PDV= 'SUN3') 
c     PARAMETER (PDV= 'VAX780')
c     PARAMETER (PDV= 'IRIS4D') 
c     PARAMETER (PDV= 'SUN4') 
c     PARAMETER (PDV= 'GATEWAY') 
c     PARAMETER (PDV= 'GENERIC') 
* 
*  THE SUPPORTED DEVICES ARE: 
*  1. CONVEX C2 using CONVEX FORTRAN compiler         (CNVXC2) 
*  2. IBM compatible PC using IBM FORTRAN/2 compiler  (IBMPC) 
*  3. Sun-3 using Sun FORTRAN compiler                (SUN3) 
*  4. VAX 780 using VAX FORTRAN compiler              (VAX780) 
*  5. IRIS-4D using Silicon Graphics FORTRAN compiler (IRIS4D) 
*  6. Sun-4 using Sun FORTRAN compiler                (SUN4) 
*  7. Gateway 2000 PC using Lahey FORTRAN compiler    (GATEWAY)
*  8. Generic; us only if other devices unavailable   (GENERIC) 
************************************************************************
*
*  PERFORM SYSTEM SPECIFIC CONFIGURATION
*
      CALL ALPHA(PDV)
*
*  EXECUTE PROGRAM ADMINISTRATOR
*
      CALL ADMIN
      END

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 AUG 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ADMIN    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-02APR96-PROGRAM STOP MOVE FROM ROUTINE AIRFOLS TO ADMIN.
************************************************************************
*
*  PROGRAM ADMINISTRATOR; PROGRAMS TRUE DRIVER WHICH ALLOWS RESTARTING
*  THE ENTIRE CODE IF REQUIRED.
*
************************************************************************
      SUBROUTINE ADMIN
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'chstg.h'
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      INCLUDE 'lists.h'
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
*  INITIALIZATIONS
* 
      CALL ZINITS
      CALL BELL(3)
* 
*  CLEAR TERMINAL SCREEN
* 
      CALL CLRSC
* 
*  WRITE PROGRAM OPENING
* 
      CALL BANNER 
      CALL TITLE
* 
*  INQUIRE ABOUT THE DEVICE TYPE
* 
      IDT= IDTYP()
*
*  HELP INEXPERIENCED PROGRAM USER WITH TUTORIAL EXAMPLE
*
      CALL TUTOR 
* 
*  EXECUTE THE AIRFOIL FAMILY CONTROLLER
* 
      CALL AFCNTL
* 
*  CLEAR TERMINAL SCREEN
* 
      CALL CLRSC
*
*  WRITE PAGE BANNER
*
      CALL BANNER 
* 
*  WRITE PROGRAM TERMINATION MESSAGE
* 
      CALL SHUTDW
*
*  PROGRAM COMPLETE
*
      STOP    '         PROGRAM TERMINATION - PROGRAM AIRFOLS COMPLETE' 
*
*  ROUTINE -ADMIN- COMPLETE 
* 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 14 DEC 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE AFCNTL   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CONTROLS SELECTION OF SECTION AND MEAN LINE CODES DESCRIBING AN
*  AIRFOIL AND THE DATA REQUIRED TO GENERATE ITS ORDINATES.
*
************************************************************************
      SUBROUTINE AFCNTL
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'afdesc.h'
      INCLUDE 'chstg.h'
      INCLUDE 'lists.h'
*
      CHARACTER RDNTCK*80, TYP*3
      LOGICAL F
* 
*  INITIALIZATIONS
* 
      F= .FALSE.
* 
*  INQUIRE ABOUT DESIRE FOR STANDARD OR NONSTANDARD AIRFOIL TYPE
* 
 199  NDX1= ICHAR('Y')
      NUMOPS= ICHAR('N')
      TYP= 'LOG'
      IAT= NQUIRY(ADVIC8, CUES1(8), LIST8, NDX1, NUMOPS, TYP) 
*
*  SELECT AIRFOIL SECTION LIST DEPENDING ON AIRFOIL TYPE;
*  STANDARD, IAT=1 OR NONSTANDARD, IAT=2
*
         IF(IAT .EQ. 1) THEN
         NUMOPS= 7
         ELSE
         NUMOPS= 7
         ENDIF
* 
*  INQUIRE ABOUT THE AIRFOIL SECTION CODE
* 
      NDX1= 1
      TYP= 'SEL'
      IAC= NQUIRY(ADVIC2, CUES1(2), LIST2, NDX1, NUMOPS, TYP) 
      CALL IMPCKP(IAC, *199)
* 
*  REQUEST THE REMAINING AIRFOIL SECTION INPUT
* 
      CALL ASINP(MLS, NDX1C, NUMOPC)
*
*  IF SELECTED AIRFOIL TYPE AND CODE ALLOWS CAMBERING OPTION,
*  INQUIRE ABOUT CAMBERING NEEDS
* 
         IF((IAT .EQ. 1) .AND. ((IAC .EQ. 1) .OR.
     +                          (IAC .EQ. 2) .OR.
     +                          (IAC .EQ. 3) .OR.
     +                          (IAC .EQ. 4) .OR.
     +                          (IAC .EQ. 5))) THEN
         NDX1= ICHAR('Y')
         NUMOPS= ICHAR('N')
         TYP= 'LOG'
         IOP1= NQUIRY(ADVIC4, CUES1(4), LIST4, NDX1, NUMOPS, TYP) 
         ELSE
         IOP1= 1
         ENDIF
*
*  TEST FOR DESIRE TO CAMBER AIRFOIL SECTION
*
         IF(IOP1 .EQ. 1) THEN 
*
*  IF SECTION IS TO BE CAMBERED,
*  TEST FOR SECTION REQUIRING USE OF A STANDARD MEAN LINE
*
            IF((IAT .EQ. 1) .AND. ((IAC .EQ. 1) .OR.
     +                             (IAC .EQ. 2) .OR.
     +                             (IAC .EQ. 3) .OR.
     +                             (IAC .EQ. 4) .OR.
     +                             (IAC .EQ. 5))) THEN
            MLC= MLS
            CALL IMPCKC(MLC, *199)
* 
*  INQUIRE ABOUT THE MEAN LINE CODE
* 
            ELSE
 299        NDX1= 1
            NUMOPS= 5
            TYP= 'SEL'
            MLC=NQUIRY(ADVIC3, CUES1(3), LIST3(NDX1), NDX1, NUMOPS, TYP) 
            CALL IMPCKC(MLC, *299)
            ENDIF
* 
*  REQUEST THE REMAINING MEAN LINE INPUT
* 
         CALL MLINP
* 
         ELSE
         DESIGC= '- none -'
	 ENDIF
* 
*  REQUEST A DESCRIPTIVE TITLE FOR THE AIRFOIL
* 
      TITLE= RDNTCK(ADVC14(37), CUES2(12), F, ' ', 'C', nouse, unused)
* 
*  REQUEST A PATH AND FILE PREFIX FOR THE OUTPUT REPORT AND DATA
* 
      PATH= RDNTCK(ADVC14(40), CUES2(13), F, ' ', 'C', nouse, unused)
      CALL OPNFIL
* 
*  GENERATE THE DESIRED AIRFOIL'S ORDINATES
* 
      CALL GENORD
* 
*  CLOSE FILES 
* 
      CALL CLSFIL
* 
*  INQUIRE ABOUT DESIRE TO DESCRIBE ADDITIONAL AIRFOILS
* 
      NDX1= ICHAR('Y')
      NUMOPS= ICHAR('N')
      TYP= 'LOG'
      IOP1= NQUIRY(ADVC11, CUES1(11), LIST11, NDX1, NUMOPS, TYP) 
      IF(IOP1 .EQ. 1) GO TO 199
* 
*  ROUTINE -AFCNTL- COMPLETE
* 
      RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 24 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ALPHA   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          MUST BE FIRST ROUTINE CALLED IN PROGRAM.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  PERFORM SYSTEM SPECIFIC CONFIGURATION AS FIRST OPERATIONS IN THE CODE.
* 
*  THE SUPPORTED DEVICES ARE: 
*  1. CONVEX C2 using CONVEX FORTRAN compiler         (CNVXC2) 
*  2. IBM compatible PC using IBM FORTRAN/2 compiler  (IBMPC) 
*  3. Sun-3 using Sun FORTRAN compiler                (SUN3) 
*  4. VAX 780 using VAX FORTRAN compiler              (VAX780) 
*  5. IRIS-4D using Silicon Graphics FORTRAN compiler (IRIS4D) 
*  6. Sun-4 using Sun FORTRAN compiler                (SUN4) 
*  7. Gateway 2000 PC using Lahey FORTRAN compiler    (GATEWAY)
*  8. Generic; us only if other devices unavailable   (GENERIC) 
*
************************************************************************
      SUBROUTINE ALPHA(PLATFM)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'pssc.h'
* 
      CHARACTER PLATFM*(*)
* 
*  INITIALIZATIONS
* 
      PDV(1:)= PLATFM
      VSDATE= ' April 1996'
      VSNUM= '1.01'
* 
 100     IF(PDV .EQ. 'CNVXC2    ') THEN
         IPDV= 1
         NLSCH= '$'
         VSDESC= 'CONVEX:UNIX:CONVEX FORTRAN'
*
         ELSE IF(PDV .EQ. 'IBMPC     ') THEN
         IPDV= 2
         NLSCH= '\'
         VSDESC= 'IBM PC:DOS:IBM FORTRAN/2'
*
         ELSE IF(PDV .EQ. 'SUN3      ') THEN
         IPDV= 3
         NLSCH= '$'
         VSDESC= 'Sun-3:UNIX:Sun FORTRAN'
*
         ELSE IF(PDV .EQ. 'VAX780    ') THEN
         IPDV= 4
         NLSCH= '$'
         VSDESC= 'VAX 780:VMS:VAX FORTRAN'
*
         ELSE IF(PDV .EQ. 'IRIS4D    ') THEN
         IPDV= 5
         NLSCH= '$'
         VSDESC= 'IRIS-4D:IRIX:SGI FORTRAN'
*
         ELSE IF(PDV .EQ. 'SUN4      ') THEN
         IPDV= 6
         NLSCH= '$'
         VSDESC= 'Sun-4:UNIX:Sun FORTRAN'
*
         ELSE IF(PDV .EQ. 'GATEWAY   ') THEN
         IPDV= 7
         NLSCH= '\'
         VSDESC= 'Gateway 2000:DOS:FORTRAN 77'
*
         ELSE IF(PDV .EQ. 'GENERIC   ') THEN
         IPDV= 8
         NLSCH= ' '
         VSDESC= '?:?:FORTRAN 77'
* 
*  RECEIVED UNSPECIFIED PLATFORM DESCRIPTOR
* 
         ELSE
            IF((IPDV .EQ. 0) .AND. (PDV .EQ. 'UNKNOWN   ')) THEN
            CALL MESSGE('D-ERROR/ NON-SUPPORTED PLATFORM /SUB ALPHA')
* 
            ELSE
            IPDV= 0
            NLSCH= ' '
            PDV= 'UNKNOWN'
            VSDESC= 'other unspecifed system'
*
*  DEFINE TARGET PLATFORM DURING RUN TIME PROCESSING
*
            CALL SYSS(IPDV)
* 
*  ASSIGN PLATFORM DESCRIPTOR VARIABLE
* 
               IF(IPDV .EQ. 1) THEN
               PDV= 'CNVXC2'
               ELSE IF(IPDV .EQ. 2) THEN
               PDV= 'IBMPC'
               ELSE IF(IPDV .EQ. 3) THEN
               PDV= 'SUN3'
               ELSE IF(IPDV .EQ. 4) THEN
               PDV= 'VAX780'
               ELSE IF(IPDV .EQ. 5) THEN
               PDV= 'IRIS4D'
               ELSE IF(IPDV .EQ. 6) THEN
               PDV= 'SUN4'
               ELSE IF(IPDV .EQ. 7) THEN
               PDV= 'GATEWAY'
               ELSE IF(IPDV .EQ. 8) THEN
               PDV= 'GENERIC'
               ENDIF
            GO TO 100
            ENDIF
         ENDIF
*
*  ROUTINE -ALPHA- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 14 JAN 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ASINP
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
C          DWS-24OCT95-CORRECTED ERROR WITH INPUT OF LEI VS. RLE.
************************************************************************
*
*  INPUT THE REQUIRED AIRFOIL SECTION DATA.
*
************************************************************************
      SUBROUTINE ASINP(MLS, NDX1C, NUMOPC)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'afdesc.h'
      INCLUDE 'chstg.h'
      INCLUDE 'lists.h'
*
      CHARACTER D1STG*10, FTYP*1, LINE*80, RDNTCK*80, TYP*3
      LOGICAL F, T
* 
*  DEFINE STATEMENT FUNCTION(S) TO;
*  CALCULATE THE LEADING-EDGE RADIUS FROM THE LEADING-EDGE INDEX
*
cdws  REAL*4 CALRLE
cdws  CALRLE(IARG, ARG)= .030608 * ARG**2 * REAL(IARG**2)
cdws  ibm fortran/2 compiler appearing to have problems with
cdws  statement functions  code replaced in-line.
* 
*          INITIALIZATIONS
* 
      F= .FALSE.
      T= .TRUE.
*
*  INQUIRE ABOUT THICKNESS TO CHORD RATIO
*
 100  LINE= RDNTCK(ADVC14(1), CUES2(1), F, ' ', 'R', nouse, TOC)
         IF(TOC .LT. 0. .OR. TOC .GE. 1.) THEN
         CALL LIMITS(LINE, '[0 .ge. TOC .lt. 1]')
         GO TO 100
         ENDIF
*
*  INQUIRE ABOUT BASIC CHORDWISE INCREMENT
*
 200  LINE= RDNTCK(ADVC14(4), CUES2(2), F, ' ', 'R', nouse, DX)
         IF(DX .LE. 0. .OR. DX .GT. 1.) THEN
         CALL LIMITS(LINE, '[0 .gt. DX .le. 1]')
         GO TO 200
         ENDIF
*
*  INQUIRE ABOUT MODEL CHORD
*
      LINE= RDNTCK(ADVC14(7), CUES2(3), F, ' ', 'R', nouse, CHD)
* 
*  PROCESS INTEGER AIRFOIL CODE, WHICH INCLUDE IAC EQUAL TO;
*               1    2    3    4    5    6    7
************************************************************************
* 
*  NACA 4-DIGIT SERIES
*
         IF(IAC .EQ. 1) THEN
         DESIGP= '4-DIGIT'
*
*  ASSIGN STANDARD MEAN LINE CODE
*
         MLS= 1
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 4
         NUMOPC= 2
************************************************************************
* 
*  NACA MODIFIED 4-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 2) THEN
         DESIGP= 'MOD 4-DIGIT'
*
*  ASSIGN STANDARD MEAN LINE CODE
*
         MLS= 1
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 4
         NUMOPC= 2
*
*  INQUIRE ABOUT LEADING EDGE RADIUS OR LEADING EDGE INDEX
*  IF INDEX RECEIVED, THEN CALCULATE RADIUS
*
         FTYP= '*'
         LEI= 0
         RLE= 0.
 300     LINE= RDNTCK(ADVC14(10), CUES2(4), F, ' ', FTYP, LEI, RLE)
            IF(FTYP .EQ. 'I') THEN
               IF(LEI .LT. 0 .OR. LEI .GT. 9.) THEN
               CALL LIMITS(LINE, '[0 .ge. LEI .le. 9]')
               GO TO 300
               ENDIF
cdws        RLE= CALRLE(LEI, TOC)
            RLE= .030608 * TOC**2 * REAL(LEI**2)
            ENDIF
*
*  INQUIRE ABOUT MAXIMUM THICKNESS LOCATION
*
 400     LINE= RDNTCK(ADVC14(15), CUES2(5), F, ' ', 'R', nouse, XMT)
            IF(XMT .LT. 0. .OR. XMT .GT. 1.) THEN
            CALL LIMITS(LINE, '[0 .ge. XMT .le. 1]')
            GO TO 400
            ENDIF
*
*  INQUIRE ABOUT TRAILING EDGE SLOPE
*
         D1DEF= CALD1(XMT, D1STG)
         LINE= RDNTCK(ADVC14(19), CUES2(6), T, D1STG, 'R', nouse, D1)
         IF(D1 .LE. 0.0) D1= D1DEF
************************************************************************
* 
*  NACA 6-SERIES
*
         ELSE IF(IAC .EQ. 3) THEN
         DESIGP= '6-SERIES'
*
*  ASSIGN STANDARD MEAN LINE CODE
*
         MLS= 4
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 1
         NUMOPC= 3
* 
*  INQUIRE ABOUT THE AIRFOIL SERIES DESIGNATION
* 
         NDX1= 1
         NUMOPS= 5
         TYP= 'SEL'
         IAD= NQUIRY(ADVC12, CUES1(12), LIST12, NDX1, NUMOPS, TYP) 
         CALL CAL6SF
************************************************************************
* 
*  NACA 6A-SERIES
*
         ELSE IF(IAC .EQ. 4) THEN
         DESIGP= '6A-SERIES'
*
*  ASSIGN STANDARD MEAN LINE CODE
*
         MLS= 5
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 1
         NUMOPC= 3
* 
*  INQUIRE ABOUT THE AIRFOIL SERIES DESIGNATION
* 
         NDX1= 1
         NUMOPS= 3
         TYP= 'SEL'
         IAD= NQUIRY(ADVC13, CUES1(13), LIST13, NDX1, NUMOPS, TYP) 
         IAD= IAD + 5
         CALL CAL6SF
************************************************************************
* 
*  NACA 16-SERIES
*
         ELSE IF(IAC .EQ. 5) THEN
         DESIGP= '16-SERIES'
*
*  ASSIGN STANDARD MEAN LINE CODE
*
         MLS= 4
*
*  ASSIGN LEADING EDGE INDEX TO CALCULATE LEADING EDGE RADIUS
*
         LEI= 4 
         RLE= 0.
cdws     RLE= CALRLE(LEI, TOC)
         RLE= .030608 * TOC**2 * REAL(LEI**2)
*
*  ASSIGN MAXIMUM THICKNESS LOCATION
*
         XMT= .5
*
*  INQUIRE ABOUT TRAILING EDGE SLOPE
*
         D1DEF= CALD1(XMT, D1STG)
         LINE= RDNTCK(ADVC14(19), CUES2(6), T, D1STG, 'R', nouse, D1)
         IF(D1 .LE. 0.0) D1= D1DEF
************************************************************************
* 
*  NACA 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 6) THEN
         DESIGP= '5-DIGIT'
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 2
         NUMOPC= 2
************************************************************************
* 
*  NACA MODIFIED 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 7) THEN
         DESIGP= 'MOD 5-DIGIT'
*
*  ASSIGN PARAMETERS FOR MEAN LINE CODES THAT THIS SECTION TYPE CAN USE
*
         NDX1C= 2
         NUMOPC= 2
*
*  INQUIRE ABOUT LEADING EDGE RADIUS
*
         FTYP= '*'
         LEI= 0 
         RLE= 0.
 500     LINE= RDNTCK(ADVC14(10), CUES2(4), F, ' ', FTYP, LEI, RLE)
            IF(FTYP .EQ. 'I') THEN
               IF(LEI .LT. 0 .OR. LEI .GT. 9.) THEN
               CALL LIMITS(LINE, '[0 .ge. LEI .le. 9]')
               GO TO 500
               ENDIF
cdws        RLE= CALRLE(LEI, TOC)
            RLE= .030608 * TOC**2 * REAL(LEI**2)
cdws  write(*,*) 'lei= ', lei, '   rle= ', rle
            ENDIF
*
*  INQUIRE ABOUT MAXIMUM THICKNESS LOCATION
*
 600     LINE= RDNTCK(ADVC14(15), CUES2(5), F, ' ', 'R', nouse, XMT)
            IF(XMT .LT. 0. .OR. XMT .GT. 1.) THEN
            CALL LIMITS(LINE, '[0 .ge. XMT .le. 1]')
            GO TO 600
            ENDIF
*
*  INQUIRE ABOUT TRAILING EDGE SLOPE
*
         D1DEF= CALD1(XMT, D1STG)
         LINE= RDNTCK(ADVC14(19), CUES2(6), T, D1STG, 'R', nouse, D1)
         IF(D1 .LE. 0.0) D1= D1DEF
************************************************************************
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
         ELSE
         CALL MESSGE('D-ERROR/ INVALID AIRFOIL CODE /SUB ASINP')
         ENDIF
************************************************************************
*  
*  ROUTINE -ASINP- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 10 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE BANNER   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  WRITE THE PROGRAM BANNER TO THE TERMINAL SCREEN.
*
************************************************************************
      SUBROUTINE BANNER 
*
*  SPECIFICATIONS
*
      INCLUDE 'pssc.h'
* 
*  WRITE A BANNER TO THE SCREEN 
* 
      WRITE(*,1000) VSNUM
 1000 FORMAT(////,T2,'AIRFOLS-',A,T51,'NASA LANGLEY RESEARCH CENTER')
*  
*  ROUTINE -BANNER- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 22 APR 88, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE BELL     
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  SENDS TERMINAL THE CONTROL STRING TO CAUSE THAT DEVICE'S BELL TO RING.
*
************************************************************************
      SUBROUTINE BELL(NRINGS)
* 
*  SPECIFICATIONS 
* 
      CHARACTER RING*1 
*
*  WRITE BELL INTEGER CONTROL TO CHARACTER STRING
*
      RING= CHAR(7)
*
*  RING BELL THE NUMBER OF TIMES SPECIFIED
*
         DO 100 I= 1,NRINGS
         WRITE(*,'(1X,A)') RING
         CALL WAITT(.0)
 100     CONTINUE
* 
*  ROUTINE -BELL- COMPLETE 
* 
      RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, dd DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE CAL6SF   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN V
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-01JUN95-CHANGED LOOP 700 INDICES OF 1,10 TO 1,11 PER C.BROOKS.
C          DWS-05MAR96-CHANGED 6&6A ELLIPSE FIT FROM PT 11 TO 12 PER C.BROOKS.
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE CAL6SF
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'af6s.h'
      INCLUDE 'afdesc.h'
*
      LOGICAL EQR
*
*  DEFINE STATEMENT FUNCTION(S) TO;
*  CALCULATE THE HYPERBOLIC COSINE OF X
*  CALCULATE THE HYPERBOLIC SINE OF X
*
cdws  REAL*4 COSH, SINH
cdws  COSH(ARG) = 0.5 * (EXP(ARG) + EXP(-ARG))
cdws  SINH(ARG) = 0.5 * (EXP(ARG) - EXP(-ARG))
cdws  ibm fortran/2 compiler appearing to have problems with
cdws  statement functions  code replaced in-line.
* 
*  INITIALIZATIONS
* 
** Open temporary extra output file ***********
      OPEN(4, FILE='6s.ran', STATUS='UNKNOWN')
 2222 format(5E13.6)
***********************************************
      NIT= 10
      NP= 201
      CRAT= 1.0
      SF= 1.0
         DO 50 IT= 1,NIT
 50      RAT(IT)= 0.0
*
*  CALCULATE THICKNESS RATIO BY ITERATING UNTIL CONVERGENCE
*  OR THE LIMIT ON THE NUMBER OF ITERATIONS
*
         DO 500 IT= 1,NIT
*
*  STORE RATIO FOR THIS ITERATING AND CALCULATE CUMULATIVE RATIO
*
         RAT(IT)= SF   
         CRAT= CRAT * RAT(IT)
*
*  CALCULATE THE X AND Y RELATIVE TO THE PRESENT THICKNESS RATIO
*
         YMAX= 0.0
            DO 100 J= 1,NP
            V1= PSI(J,IAD) * CRAT
            V2= PHI(J) - (EPS(J,IAD) * CRAT)
cdws        XT(J)= -2.0 * COSH(V1) * COS(V2)
            XT(J)= -2.0 * (0.5 * (EXP(V1) + EXP(-V1))) * COS(V2)
cdws        YT(J)=  2.0 * SINH(V1) * SIN(V2)
            YT(J)=  2.0 * (0.5 * (EXP(V1) - EXP(-V1))) * SIN(V2)
*
*  LOCATE THE MAXIMUM Y/C WHICH IS THE PEAK LOCATION
*
               IF(YT(J) .GT. YMAX) THEN
               YMAX= YT(J)
               XYM= XT(J)
               ENDIF
 100        CONTINUE
*
*  ASSIGN THE X STARTING, X ENDING AND X RANGE VALUES
*
         XS= XT(1)
         XE= XT(NP)
         XRNG= XE - XS
*
*  CALCULATE THE FIRST DERIVATIVE AT YT
*
         YTP(1)= 999.E8
            DO 200 J= 2,NP
 200        YTP(J)= DERV(J, 5, NP, XT, YT)
*
*  CALCULATE THE SECOND DERIVATIVE AT YT
*
         YTPP(1)= -999.E8
            DO 300 J= 3,NP
 300        YTPP(J)= DERV(J, 5, NP, XT, YTP)
*
*  CALCULATE X LOCATION THAT THE SLOPE FIRST CHANGES SIGN
*
         XTP= 1.0
            DO 400 J= 2,NP
            I= J-1
               IF(YTP(J).LT.0.0 .AND. YTP(I).GT.0.0) THEN
               XTP= XT(I) + YTP(I) * (XT(J) - XT(I)) / (YTP(I) - YTP(J))
               GO TO 401
               ENDIF
 400        CONTINUE
*
*  CALCULATE Y LOCATION THAT THE SLOPE FIRST CHANGES SIGN
*
 401     CALL NTRP(NP, XT, YT, XTP, YM)
*
*  CALCULATE THE THICKNESS RATIO THEN TEST FOR CONVERGENCE
*
         TR= 2. * YM / XRNG
         SF= TOC / TR
         IF(EQR(TOC,0.0) .OR. (ABS(SF-1.0) .LT. 0.0001)) GO TO 501
 500     CONTINUE
*
*  SCALE THE 6 SERIES VARIABLES LINEARLY TO THERE EXACT VALUES
*
 501     DO 600 J= 1,NP
         XT(J)= (XT(J) - XS) / XRNG
         YT(J)= SF * YT(J) / XRNG
         YTP(J)= SF * YTP(J)
         YTPP(J)= SF * YTPP(J) * XRNG
         if(YTPP(J).NE.0) rac=(1.+YTP(J)**2)**1.5/YTPP(J)
         write(4,2222)XT(J),YT(J),YTP(J),YTPP(J),rac
 600     CONTINUE
*
      YMAX= YMAX * SF / XRNG
      XYM= (XYM - XS) / XRNG
      XTP= (XTP - XS) / XRNG
      YM= YM * SF / XRNG
*
*  FIT TILTED ELLIPSE AT ELEVENTH PROFILE POINT
*
         IF(TOC .GT. 0.0) THEN
         XT12= XT(12)
         YT12= YT(12)
         YTP12= YTP(12)
*
*  CALCULATE THE APPROXIMATE SOLUTION, CN (USING THE FACTOR 0.1)
*
         CN= (2. * YTP12) - (YT12 / XT12) + 0.1
         RNUMER= XT12 * (YTP12 * XT12 - YT12)
         DEMON= XT12 * (2. * YTP12 - CN) - YT12
         AN= RNUMER / DEMON
         ANSQ= AN * AN
         RNUMER= (YT12 - CN * XT12)**2
         DEMON= 1. - ((XT12 - AN)**2 / ANSQ)
         BN= SQRT(RNUMER / DEMON)
         BNSQ= BN * BN
         BNQU= BNSQ * BNSQ
         RNP= BNSQ / AN
*
            DO 700 J= 1,12
C           V1= 1. - ((XT(J) - AN)**2 / ANSQ)
            V1= 1. - ((XT(J) - AN)/AN)**2 
            V2= CN * XT(J)
            YT(J)= (BN * SQRT(V1)) + (V2)
               IF(XT(J) .GT. 0.0) THEN
               V3= YT(J) - (V2)
               YTP(J)= BNSQ * (AN - XT(J)) / ANSQ / V3 + CN
               YTPP(J)= -BNQU / ANSQ / V3**3
               if(YTPP(J).NE.0) rac=(1.+YTP(J)**2)**1.5/YTPP(J)
               write(4,2222)XT(J),YT(J),YTP(J),YTPP(J),rac
               ENDIF
 700        CONTINUE
         ENDIF
*
*  ROUTINE -CAL6SF- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 28 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION CALA1       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE A1 VARIABLE USED FOR THE MODIFIED 4-DIGIT THICKNESS
*  DISTRIBUTION.
*
************************************************************************
      REAL*4 FUNCTION CALA1(A0, A2, A3, XMT)
* 
*  INITIALIZATIONS
* 
      SRXMT= SQRT(XMT)
      XMTSQ= XMT * XMT
      V1= A0 * .5 * (1. / SRXMT)
      V2= A2 * 2. * XMT
      V3= A3 * 3. * XMTSQ
* 
      CALA1= -V1 - V2 - V3
* 
*  ROUTINE -CALA1- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 28 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION CALA2       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE A2 VARIABLE USED FOR THE MODIFIED 4-DIGIT THICKNESS
*  DISTRIBUTION.
*
************************************************************************
      REAL*4 FUNCTION CALA2(A0, A3, XMT)
* 
*  INITIALIZATIONS
* 
      XMTSQ= XMT * XMT
      V1= .1 / XMTSQ
      V2= A0 * (.5 / XMT**1.5)
      V3= A3 * 2. * XMT
* 
      CALA2= -V1 + V2 - V3
* 
*  ROUTINE -CALA2- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 28 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION CALA3       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE A3 VARIABLE USED FOR THE MODIFIED 4-DIGIT THICKNESS
*  DISTRIBUTION.
*
************************************************************************
      REAL*4 FUNCTION CALA3(A0, D1, XMT)
* 
*  INITIALIZATIONS
* 
      OMXMT= 1. - XMT
      OMXMSQ= OMXMT * OMXMT
      XMTCU= XMT * XMT * XMT
      V1= .1 / XMTCU
      V2= (2. * D1 * OMXMT - .588) / (2. * XMT * OMXMSQ)
      V3= (3. * A0) / (8. * XMT**2.5)
* 
      CALA3= V1 + V2 - V3
* 
*  ROUTINE -CALA3- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 30 MAR 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION CALD1       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE D1 VARIABLE USED FOR THE MODIFIED 4-DIGIT THICKNESS
*  DISTRIBUTION.
*
************************************************************************
      REAL*4 FUNCTION CALD1(XMT,
     +                    D1STG)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'chstg.h'
*
      CHARACTER D1STG*10
* 
*  INITIALIZATIONS
* 
      XMTSQ= XMT * XMT
      C1= 2.24
      C2= 5.42
      C3= 12.3
      C4= 0.878
      CALD1= .1 * (C1 - (C2*XMT) + (C3*XMTSQ)) / (1. - (C4*XMT)) 
* 
*  WRITE D1 DEFAULT VALUE TO THE CORRECT CUE STRING FOR DISPLAY 
* 
      WRITE(CUES2(6)(27:37),'(F11.5)') CALD1
      D1STG= CUES2(6)(27:37)
* 
*  ROUTINE -CALD1- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 24 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION CALF    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATE THE SECANT OF THETA, F.
*
************************************************************************
      REAL*4 FUNCTION CALF(TANTH,
     +                   FSQ)
* 
*  CALCULATE THE SECANT OF THETA
* 
      TANTSQ= TANTH * TANTH
      CALF= SQRT(1. + TANTSQ)
      FSQ= CALF * CALF
*
*  ROUTINE -CALF- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 24 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE CAMBER   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATE ORNINATES FOR CAMBER OF SPECIFIED MEAN LINE.
*
************************************************************************
      SUBROUTINE CAMBER(I)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
c
      logical eqr
*
*  CALCULATE ORNINATES FOR CAMBER OF SPECIFIED MEAN LINE
*
      CALL CDESIG(I, MLC, F, TANTH, THP, YCMB)
*
      SINTH= TANTH / F
      COSTH= 1. / F
*
*  CALCULATE UPPER AND LOWER AIRFOIL SURFACE ORNINATES
*
      V1= Y * SINTH
      XL= X(I) + V1
      XU= X(I) - V1
*
      V2= Y * COSTH
      YL= YCMB - V2
      YU= YCMB + V2
*
*  CALCULATE YP, THE FIRST DERIVATIVE OF Y FOR THE UPPER AND LOWER SURFACE
*
c  the following if/then-else-end structure is added only because of the use of
c  the original code for 6 & 6a series camber in the routine ml6s; if this code
c  were rewritten the inclusion of this structure and the logical eqr statement
c  above could probably be removed and managed within the routine ml6s.   -dws-
               if(eqr(tanth,0.0)) then
               ypu= 0.0 
               ypl= 0.0 
               else if(i .eq. 1) then
               xl= 0.0
               xu= 0.0
               yl= 0.0
               yu= 0.0
               xcl= 0.0
               xcu= 0.0
               ycl= 0.0
               ycl= 0.0
               ypu= -1/tanth   
               ypl= -1/tanth 
               else
      V1= TANTH * F
      V2= Y * THP
      V3= V2 * TANTH
      V4= YP * TANTH
      YPL= (V1 - YP + V3) / (F + V4 + V2)
      YPU= (V1 + YP - V3) / (F - V4 - V2)
               endif
*
*  DIMENSION TO THE MODEL CHORD LENGTH
*
      XCL= XL * CHD
      XCU= XU * CHD
*
      YCL= YL * CHD
      YCU= YU * CHD
*
*  ROUTINE -CAMBER- COMPLETE 
* 
      RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 16 DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE CDESIG   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE ORNINATES FOR A SPECIFIED AIRFOIL CAMBER BY PROCESSING
*  THE MEAN LINE CODE, MLC.
*
************************************************************************
      SUBROUTINE CDESIG(I, MLC,
     +                  F, TANTH, THP, YCMB)
* 
*  NACA 2-DIGIT
*
         IF(MLC .EQ. 1) THEN
         CALL ML2D(I, F, TANTH, THP, YCMB)
* 
*  NACA 3-DIGIT
*
         ELSE IF(MLC .EQ. 2) THEN
         CALL ML3D(I, F, TANTH, THP, YCMB)
* 
*  NACA 3-DIGIT REFLEX
*
         ELSE IF(MLC .EQ. 3) THEN
         CALL ML3DR(I, F, TANTH, THP, YCMB)
* 
*  NACA 6-SERIES
*
         ELSE IF(MLC .EQ. 4) THEN
         CALL ML6S(I, F, TANTH, THP, YCMB)
* 
*  NACA 6A-SERIES
*
         ELSE IF(MLC .EQ. 5) THEN
         CALL ML6S(I, F, TANTH, THP, YCMB)
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
         ELSE
         CALL MESSGE('D-ERROR/ INVALID MEAN LINE CODE /SUB CDESIG')
         ENDIF
*
*  ROUTINE -CDESIG- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 AUG 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE CLRSC    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          ASSUMES A CALL TO DEFINE THE CLR CODE HAS BEEN MADE PREVIOUSLY.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-19FEB92-SEPARATED TERM. DEFINITIONS AND ACTUAL FUNCTION.
************************************************************************
*
*  SENDS TERMINAL THE CONTROL STRING TO CAUSE THAT DEVICE'S SCREEN TO CLEAR.
*
************************************************************************
      SUBROUTINE CLRSC
* 
*  SPECIFICATIONS 
* 
      CHARACTER CLR*24
      COMMON /CLRCOD/ CLR
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
* 
*  NO-OP PROCESSING WHEN IDT=0
* 
      IF(IDT .EQ. 0) GO TO 999
*
*  CLEAR TERMINAL SCREEN
*
      WRITE(*,'(1X,A)') CLR 
* 
*  ROUTINE -CLRSC- COMPLETE 
* 
 999  RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 14 DEC 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE CLSFIL   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE CLSFIL
* 
*          SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
* 
      REAL*4 V1, V2
*
*  MERGE AUXILIARY FILE WITH DATA FILE
*
         DO 100 I= 1,KOUNTX
         READ(IUA,REC=I) V1, V2
         WRITE(IUD,'(2F13.6)') V1, V2
 100     CONTINUE
* 
*  CLOSE GLOBOL FILES
*
      CLOSE(IUA, STATUS='DELETE')
      CLOSE(IUD)
      CLOSE(IUR)
*
*  ROUTINE -CLSFIL- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 19 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE DEFCLR   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-18FEB92-REPLACED GOTO WITH CASE STRUCTURE (IF-THEN-ELSE).
C          DWS-18FEB92-MODIFIED TO ADD TERM. TYPES IBMPC, SUNWS, AND ANSIT.
C          DWS-19FEB92-MODIFIED TO ADD TERM. TYPES VT50, VT100, AND VT200.
C          DWS-01APR96-CORRECTED ERROR WITH TERM. TYPE XTERM.
************************************************************************
*
*  DEFINES THE CODE THAT CLEARS THE EXECUTING TERMINALS SCREEN.
*
************************************************************************
      SUBROUTINE DEFCLR(IDT)
* 
*  SPECIFICATIONS 
* 
      CHARACTER CH*1, CLR*24
      COMMON /CLRCOD/ CLR
      DIMENSION ICOD(9,24)
*
*  ASSIGN INTEGER CONTROL SEQUENCES
*  PROCESS INTEGER DEVICE TYPE CODE, WHICH INCLUDE IDT EQUAL TO;
*  0, 1, 2, 3, 4, 5, 6, 7, 8
************************************************************************
* 
*  NO-OP PROCESSING WHEN IDT=0
* 
         IF(IDT .EQ. 0) THEN
         GO TO 999
************************************************************************
* 
*  T4107 - TEKTRONIX 4107
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Us  Ec % ! 1  Ec [ 1 ; 1 H  Ec [ 2 J
*  ENTER ALPHA MODE; SELECT MODE ANSI; POSITION CURSOR TO 1,1;
*  ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 3) THEN
         INDX= 1
         DATA (ICOD(1,I),I=1,24) /31, 27,37,33,49, 27,91,49,59,49,72,
     .                               27,91,50,74, 9*0/
************************************************************************
* 
*  VT240 - DEC VT240 TERMINAL WITH REGIS GRAPHICS
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Ec \  Ec [ 1 ; 1 H  Ec [ 2 J
*  EXIT REGIS, SET TEXT MODE; POSITION CURSOR TO 1,1; ERASE
*  ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 8) THEN
         INDX= 2
         DATA (ICOD(2,I),I=1,24) /27,92, 27,91,49,59,49,72,
     .                               27,91,50,74, 12*0/
************************************************************************
* 
*  VTERM - IBM PERSONAL COMPUTER VTERM PACKAGE
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Us  Gs  Ec Ff  Ec [ 1 ; 1 H
*  ENTER GRAPHIC ALPHA MODE; ENTER GRAPHIC MODE; ERASE SCREEN 
*  RETURNING TO VT100 MODE; POSITION CURSOR TO 1,1.
*
         ELSE IF(IDT .EQ. 9) THEN
         INDX= 3
         DATA(ICOD(3,I),I=1,24) /31, 29, 27,12, 27,91,49,59,49,72,
     .                              14*0/
************************************************************************
* 
*  IBMPC - IBM PERSONAL COMPUTER CONFIGURED WITH DEVICE=ANSI.SYS
*  IBMCP - IBM PC COMPATIBLE CONFIGURED WITH DEVICE=ANSI.SYS
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Ec [ 1 ; 1 H  Ec [ 2 J
*  POSITION CURSOR TO 1,1; ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 2) THEN
         INDX= 4
         DATA (ICOD(4,I),I=1,24) /27,91,49,59,49,72, 27,91,50,74,
     .                               14*0/
************************************************************************
* 
*  SUNWS - SUN MICROSYSTEMS WORKSTATION CONSOLE
*  MICRO - MICROTERM
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  ^L
*  ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 4) THEN
         INDX= 5
         DATA (ICOD(5,I),I=1,24) /12, 23*0/
************************************************************************
* 
*  ANSIT - ANSI TERMINAL OR ANSI TERMINAL EMULATION
*  IRISA - IRIS EMULATING AN ANSI TERMINAL
*  VT1NP - DEC VT100 TERMINAL WITH NO PADDING
*  XTERM - TERMINAL EMULATOR FOR X
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Ec [ H  Ec [ 2 J
*  POSITION CURSOR TO 1,1; ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF((IDT .EQ. 1) 
     .      .OR. (IDT .EQ. 10)) THEN
         INDX= 6
         DATA (ICOD(6,I),I=1,24) /27,91,72, 27,91,50,74, 17*0/
************************************************************************
* 
*  VT_50 - DEC VT50 TERMINAL
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Ec H  Ec J
*  POSITION CURSOR TO 1,1; ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 5) THEN
         INDX= 7
         DATA (ICOD(7,I),I=1,24) /27,72, 27,74, 20*0/
************************************************************************
* 
*  VT100 - DEC VT100 TERMINAL
*  VERSA - MACINTOSH VERSATERM PACKAGE
*  IBMCL - IBM PERSONAL COMPUTER CLONE
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  5 0  Ec [ ; H  Ec [ 2 J
*  POSITION CURSOR TO 1,1; ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 6) THEN
         INDX= 8
         DATA (ICOD(8,I),I=1,24) /53,48, 27,91,59,72, 27,91,50,74,
     .                               14*0/
************************************************************************
* 
*  VT200 - DEC VT200 TERMINAL
*
*  CONTROL SEQUENCES DEFINED AS,
* 
*  Ec [ H  Ec [ J
*  POSITION CURSOR TO 1,1; ERASE ENTIRE DIALOG BUFFER.
*
         ELSE IF(IDT .EQ. 7) THEN
         INDX= 9
         DATA (ICOD(9,I),I=1,24) /27,91,72, 27,91,74, 18*0/
************************************************************************
* 
*  RECEIVED INTEGER CODE SPECIFING NON-SUPPORTED DEVICE TYPE, USE NO-OP
* 
         ELSE
         CALL MESSGE('T-ERROR/ NO-OP DEVICE MODE')
         IDT= 0
         GO TO 999
         ENDIF
************************************************************************
*
*  WRITE CLEAR SCREEN INTEGER CONTROL SEQUENCE TO CHARACTER STRING
*
      CLR= CHAR(ICOD(INDX,1))
         DO 100 I= 2,24
         CH= CHAR(ICOD(INDX,I))
         CLR= CLR(1:I-1) // CH
 100     CONTINUE
* 
*  ROUTINE -DEFCLR- COMPLETE 
* 
 999  RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 12 JUN 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION DERV    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          POINT FORMULA DETERMINATE ARGUMENT (M) MUST BE OF RANGE 1 TO 5.
C          NUMBER OF POINTS (NP) MUST EXCEED THE POINT FORMULA DERIVED.
C          MAXIMUM N POINT FORMULA THAT CAN BE USED IS 11.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          ???-08JAN68-EXTRACTED FROM MATH LIB. FOR USE IN PROGRAM LADSON.
C          DWS-12JUN91-CLEANED UP AND STANDARDIZED FOR PROGRAM AIRFOLS.
C          DWS-06MAR92-ERROR MESSAGE ADDED FOR ILLEGAL ARGUMENT RECEIVED.
************************************************************************
*
*  FINDS THE DERIVATIVE AT A GIVEN POINT, L, FOR THE DESIRED X AND Y IN
*  A GIVEN TABLE.  THE N-POINT LAGRANGIAN FORMULA IS USED WHERE N IS ODD.
*  THE ORIGINAL ROUTINE DIF CAME FROM THE FORTRAN MATH LIBRARY USED ON
*  THE NASA LANGLEY CYBERS WITH NOS.
*
*  L    = INTEGER, THE POINT OF X AND Y AT WHICH DERIVATIVE IS FOUND
*  M    = INTEGER, 1-5, TO DETERMINE THE POINT FORMULA, N;  N=2*M+1
*  NP   = INTEGER, THE NUMBER OF POINTS IN ARRAY OF VARIABLES
*  VARI = REAL ARRAY OF INDEPENDENT VARIABLE, X;  VARI(NP)
*  VARD = REAL ARRAY OF DEPENDENT VARIABLE, Y;  VARD(NP)
*
************************************************************************
      REAL*4 FUNCTION DERV(L, M, NP, VARI, VARD)
* 
*  SPECIFICATIONS 
* 
      REAL*4 VARD(NP), VARI(NP), X(11), Y(11)
* 
*  INITIALIZATIONS
* 
      M1= M + 1
      M2= NP - M1
      N= (2 * M) + 1
*
*  TEST PARAMETERS TO CONFORM TO FORMULA RESTRICTIONS
*
         IF((M .GE. 1) .AND. (M .LE. 5) .AND. (N .LE. NP)) THEN 
*
            IF((L .LE. M1) .OR. (N .EQ. NP)) THEN
            K= L
            ELSE IF(L .LT. M2) THEN
            K= M1
            ELSE
            K= L - (NP - N)
            ENDIF
*
*  TRANSFER NUMBER OF POINTS FROM LOCATIONS OF CONSIDERATION INTO X AND Y
*
         MX= L - K
            DO 20 J= 1,N
            MJ= MX + J
            X(J)= VARI(MJ)
            Y(J)= VARD(MJ)
 20         CONTINUE
*
         A= 1.
         B= 0.
         C= 0.
            DO 40 J= 1,N
               IF(J .NE. K) THEN
               P= 1.
                  DO 30 I= 1,N
                     IF(I .NE. J) THEN
                     P= P * (X(J) - X(I))
                     ENDIF
 30               CONTINUE
               T= X(K) - X(J)
               B= B + (Y(J) / (P * T))
               A= A * T
               C= C + (1. / T)
               ENDIF
 40         CONTINUE
*
         DERV= (A * B) + (Y(K) * C)
* 
*  RECEIVED INCORRECT PARAMETERS
* 
         ELSE
         CALL MESSGE('D-ERROR/ INCORRECT ARGUMENT USAGE /SUB DERV')
         ENDIF
*
*  ROUTINE -DERV- COMPLETE 
*
      RETURN
      END

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 09 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION EQR    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  COMPARES TWO REAL NUMBERS FOR EQUALITY USING A TOLERANCE VALUE.
*
************************************************************************
      LOGICAL FUNCTION EQR(RVAL1, RVAL2)
* 
*  SPECIFICATIONS 
* 
      REAL*4 ADIF, RVAL1, RVAL2
* 
*  INITIALIZATIONS
* 
      EQR= .FALSE.
      TOLR= .000001
* 
*  TEST THE ABSOLUTE DIFFERENCE TO BE LESS THAN THE TOLERANCE
* 
      ADIF= ABS(RVAL2 - RVAL1)
      IF(ADIF .LT. TOLR) EQR= .TRUE.
*
*  ROUTINE -EQR- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 02 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE FRMCAM   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  WRITES TO THE OUTPUT REPORT FORM THE CAMBER SPECIFIC DATA.
*
************************************************************************
      SUBROUTINE FRMCAM
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
*
*  PRINT CAMBER SPECIFIC DATA
* 
*  NACA 2-DIGIT
*
         IF(MLC .EQ. 1) THEN
         WRITE(IUR,1000) CMB
 1000    FORMAT(T3,F9.4,T15,'= MAX. CAMBER / CHORD, p  (CMB)')
         WRITE(IUR,1010) CMY
 1010    FORMAT(T3,F9.6,T15,'= MAX. CAMBER LOCATION, m  (CMY)')
* 
*  NACA 3-DIGIT
*
         ELSE IF(MLC .EQ. 2) THEN
         WRITE(IUR,1020) CMB
 1020    FORMAT(T3,F9.4,T15,'= CAMBER PARAMETER, k1  (CMB)')
         WRITE(IUR,1030) CMY
 1030    FORMAT(T3,F9.6,T15,
     +          '= ZERO CAMBER LINE CURVATURE LOCATION, r  (CMY)')
*
*  NACA 3-DIGIT REFLEX
*
         ELSE IF(MLC .EQ. 3) THEN
         WRITE(IUR,1020) CMB
         WRITE(IUR,1030) CMY
         WRITE(IUR,1040) RK2OK1
 1040    FORMAT(T3,F9.6,T15,
     +          '= RATIO OF CAMBER PARAMETERS, k2/k1  (RK2OK1)')
* 
*  NACA 6-SERIES OR 6A-SERIES
*
         ELSE IF((MLC .EQ. 4) .OR. (MLC .EQ. 5)) THEN
         WRITE(IUR,1050) CMBNMR
 1050    FORMAT(T3,I9,T15,'= NUMBER OF CAMBER LINES TO SUM  (CMBNMR)')
         WRITE(IUR,'('' CLI(I)   ='',10F13.6)') (CLI(I),I=1,CMBNMR)
         WRITE(IUR,'('' A(I)     ='',10F13.6)') (A(I),I=1,CMBNMR)
         ENDIF
*
*  ROUTINE -FRMCAM- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 02 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE FRMPRF   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN V
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-05MAR96-CHANGED 6&6A ELLIPSE FIT FROM PT 11 TO 12 PER C.BROOKS.
************************************************************************
*
*  WRITES TO THE OUTPUT REPORT FORM THE PROFILE SPECIFIC DATA.
*
************************************************************************
      SUBROUTINE FRMPRF
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'af6s.h'
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
*
*  PRINT PROFILE SPECIFIC DATA
*
*  NACA 4-DIGIT OR 5-DIGIT
*
         IF((IAC .EQ. 1) .OR. (IAC .EQ. 6)) THEN
         WRITE(IUR,'(T3,F9.6,T15,''= L.E.RADIUS  (RLE)'')') RLE
* 
*  NACA MODIFIED 4-DIGIT OR 16-SERIES OR MODIFIED 5-DIGIT
*
         ELSE IF((IAC .EQ. 2) .OR. (IAC .EQ. 5) .OR. (IAC .EQ. 7)) THEN
         WRITE(IUR,'(T3,F9.6,T15,''= L.E.RADIUS  (RLE)'')') RLE
         WRITE(IUR,'(T3,F9.6,T15,''= MAX. THICKNESS LOCATION  (XMT)'')')
     +         XMT
         WRITE(IUR,'(T3,F9.6,T15,''= TRAILING EDGE SLOPE  (D1)'',/)') D1
         WRITE(IUR,'('' A0,1,2,3 ='',4F13.6)') A0, A1, A2, A3
         WRITE(IUR,'('' D0,1,2,3 ='',4F13.6)') D0, D1, D2, D3
         WRITE(IUR,'('' RC =      '',1F13.3)') RC
* 
*  NACA 6-SERIES OR 6A-SERIES
*
         ELSE IF((IAC .EQ. 3) .OR. (IAC .EQ. 4)) THEN
         WRITE(IUR,'('' RAT(I)   ='',10F13.6)') (RAT(I),I=1,IT)
         WRITE(IUR,'(T3,I9,T15,''= NUMBER OF ITERATIONS  (IT)'')') IT
         WRITE(IUR,1000) SF
 1000    FORMAT(T3,F9.6,T15,'= T/C RATIO, INPUT TO COMPUTED  (SF)')
         WRITE(IUR,1010) CRAT
 1010    FORMAT(T3,F9.6,T15,'= CUMULATIVE SCALING OF EPS,PSI  (CRAT)')
         WRITE(IUR,'(T3,F9.6,T15,''= MAXIMUM Y/C  (YMAX)'')') YMAX
         WRITE(IUR,'(T3,F9.6,T15,''= PEAK LOCATION  (XYM)'')') XYM
         WRITE(IUR,1020) XTP, YM
 1020    FORMAT
     +   (T3,F9.6,F10.6,T25,'= SLOPE SIGN CHANGE LOCATION  (XTP,YM)')
         WRITE(IUR,1030) XT(12)
 1030    FORMAT(T3,F9.6,T15,'= X/C FIT OF ELLIPSE  (XT(12))')
         WRITE(IUR,1040) YT(12)
 1040    FORMAT(T3,F9.6,T15,'= Y/C FIT OF ELLIPSE  (YT(12))')
         WRITE(IUR,1050) YTP(12)
 1050    FORMAT(T3,F9.6,T15,'= SLOPE FIT OF ELLIPSE  (YTP(12))')
         WRITE(IUR,1060) RNP
 1060    FORMAT(T3,F9.6,T15,
     +   '= RADIUS OF ELLIPSE, ORIGIN TO XT(12)/C,YT(12)/C  (RNP)')
         ENDIF
*
*  ROUTINE -FRMPRF- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE GENORD   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  GENERATE ORDINATES FOR THE SPECIFIED AIRFOIL.
*
************************************************************************
      SUBROUTINE GENORD
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
*
*  CALCULATE THE X'S FOR THE ORNINATE LOCATIONS
*
      CALL XS
*
*  FOR EACH OF THE X LOCATIONS CALCULATE THE ORNINATE
*
         DO 100 I= 1, KOUNTX
*
*  CALCULATE ORNINATES FOR PROFILE OF SPECIFIED THICKNESS DISTRIBUTION
*
         CALL PROFIL(I)
*
*  FORMAT THE OUTPUT FORM AND WRITE OUT THE INITIAL INFORMATION
*
         IF(I .EQ. 1) CALL WRFORM
*
*  IF CAMBERED, CALCULATE ORNINATES FOR CAMBER OF SPECIFIED MEAN LINE
*
         IF(MLC .GT. 0) CALL CAMBER(I)
*
*  WRITE PRESENT ORNINATE DATA AS AN ENTRY TO THE OUTPUT FORM
*
         CALL WRNTRY(I)
*
100      CONTINUE
*
*  ROUTINE -GENORD- COMPLETE 
* 
      RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 04 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ICHK     
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-01APR96-ADDED A PATCH TO ENABLE EXIT TO ACT AS RESTART.
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE ICHK(ADVIC, TEXT, NDX1, NUMOPS, TYP, *, *, *)
* 
*  SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
      CHARACTER*(*) ADVIC(*), FORM*5, TEXT, TYP*3 
*
*  RECURSIVE ENTRIES
*
      ENTRY ICHK1(ADVIC, TEXT, NDX1, NUMOPS, TYP, *, *, *) 
* 
*  INITIALIZATIONS
* 
      ASSIGN 9990 TO LRET
      IOP= 0 
      FORM= '(Ixx)'
      NCHR= NDCH(TEXT) 
      WRITE(FORM(3:4),'(I2.2)') NCHR
************************************************************************
* 
*  TEST FOR ENTRY OF <CR> 
* 
         IF(TEXT(:1) .EQ. ' ') THEN 
            IF(NCHR .EQ. 0) THEN
            IOP= IOPCR
            TEXT(:4)= '<CR>'
            ASSIGN 9991 TO LRET
            ENDIF 
* 
*  TEST FOR ENTRY OF </>
* 
         ELSE IF(TEXT(:1) .EQ. '/') THEN
         IOP= IOPSL
*
*  TEST FOR PROMPT MODE
*
            IF(MPR .NE. ITRUE) THEN
            CALL PROMPT(TEXT)
            ASSIGN 9992 TO LRET
            ELSE
            IF(NCHR .EQ. 1) ASSIGN 9992 TO LRET
            ENDIF
* 
*  TEST FOR ENTRY OF <?>
* 
         ELSE IF(TEXT(:1) .EQ. '?' .AND. NCHR .EQ. 1) THEN
         IOP= IOPQM
	 CALL XPLAIN(ADVIC, .TRUE.)
         ASSIGN 9992 TO LRET
* 
*  TEST FOR ENTRY OF <E>
* 
         ELSE IF(TEXT(:1) .EQ. 'E' .OR. TEXT(:1) .EQ. 'e'
     .           .AND. NCHR .EQ. 1) THEN
         IOP= IOPE
         ASSIGN 9993 TO LRET
*
*  PATCH TO CAUSE A RESTART FOR EXIT
*
         IF(MEX .NE. ITRUE) CALL RESTRT
* 
*  TEST FOR ENTRY OF <Q>
* 
         ELSE IF(TEXT(:1) .EQ. 'Q' .OR. TEXT(:1) .EQ. 'q'
     .           .AND. NCHR .EQ. 1) THEN
         IOP= IOPQ
         ASSIGN 9999 TO LRET
* 
*  TEST FOR ENTRY ERROR  (ERR=_)
* 
         ELSE IF(IOS .GT. 0) THEN 
         IOP= -(NOP + 1)
* 
*  AN INVALID PROGRAM CONTROL ENTRY WAS RECEIVED
* 
         ELSE IF(TYP .EQ. 'CNT') THEN 
************************************************************************
* 
*  TEST FOR VALID SELECTION TYPE ENTRY
* 
         ELSE IF(TYP .EQ. 'SEL') THEN 
            DO 10 I= 1,NCHR 
            IF(ICHAR(TEXT(I:I)) .LT. ICHAR('0') .OR. 
     .         ICHAR(TEXT(I:I)) .GT. ICHAR('9')) GO TO 11
 10         CONTINUE
         READ(TEXT,FORM) ISEL
         IF(ISEL .GE. NDX1 .AND. ISEL .LE. NDX1+NUMOPS-1) IOP= ISEL
 11      CONTINUE
* 
*  TEST FOR VALID ANSWER TYPE ENTRY 
* 
         ELSE IF(TYP .EQ. 'ANS') THEN 
         IOP= NCHR 
* 
*  AFTER CONVERTING ENTRY TO ALL UPPER CASE
*  TEST FOR VALID LOGICAL TYPE ENTRY
* 
         ELSE IF(TYP .EQ. 'LOG') THEN 
         IF(TEXT(:1) .GE. 'a' .AND. TEXT(:1) .LE. 'z')
     .   TEXT(:1)= CHAR(ICHAR(TEXT(:1))-32)
         IF(TEXT(:1) .EQ. CHAR(NDX1) .AND. NCHR .EQ. 1) IOP= 1 
         IF(TEXT(:1) .EQ. CHAR(NUMOPS) .AND. NCHR .EQ. 1) IOP= 2 
         ENDIF
*
*  TEST FOR EXAMPLE MODE
*
      IF(MEX .EQ. ITRUE) ASSIGN 9993 TO LRET
*
*  TEST FOR REQUIREMENT TO ISSUE AN ERROR MESSAGE
*
         IF(IOP .LT. -NOP .OR. IOP .EQ. 0) THEN
         ASSIGN 9992 TO LRET
         CALL ISSUER(TEXT, NDX1, NUMOPS, TYP) 
         ENDIF
* 
      GO TO LRET
* 
*  ROUTINE -ICHK- COMPLETE 
* 
 9990 RETURN 
 9991 RETURN 1
 9992 RETURN 2
 9993 RETURN 3
 9999 STOP    '         PROGRAM TERMINATION - USER REQUESTED' 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 10 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION IDTYP    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      INTEGER*4 FUNCTION IDTYP()
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'chstg.h'
      INCLUDE 'lists.h'
*
      CHARACTER TYP*3
* 
*  INITIALIZATIONS
* 
      NDX1= 1
      NUMOPS= 10
      TYP= 'SEL'
* 
*  INQUIRE ABOUT THE DEVICE TYPE
* 
      IDT= NQUIRY(ADVIC1, CUES1(1), LIST1, NDX1, NUMOPS, TYP) 
* 
*  DEFINE THE CLEAR SCREEN CODE FOR THE SELECTED DEVICE
* 
      CALL DEFCLR(IDT)
* 
      IDTYP= IDT
*
*  ROUTINE -IDTYP- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 06 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE IMPCKC   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CHECKS THE MEAN LINE CODE, MLC, TO CONFIRM IT IS A CURRENTLY 
*  IMPLEMENTED OPTION.
*
************************************************************************
      SUBROUTINE IMPCKC(MLC, *)
*
*  SPECIFICATIONS
*
      LOGICAL NONIMP
*
*  INITIALIZATIONS
*
      NONIMP= .FALSE.
* 
*  NACA 2-DIGIT
*
         IF(MLC .EQ. 1) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 3-DIGIT
*
         ELSE IF(MLC .EQ. 2) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 3-DIGIT REFLEX
*
         ELSE IF(MLC .EQ. 3) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 6-SERIES
*
         ELSE IF(MLC .EQ. 4) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 6A-SERIES
*
         ELSE IF(MLC .EQ. 5) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
         ENDIF
*
*  ROUTINE -IMPCKC- COMPLETE 
* 
         IF(NONIMP) THEN
         RETURN 1
         ELSE
         RETURN
         ENDIF
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 06 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE IMPCKP   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CHECKS THE INTEGER AIRFOIL CODE, IAC, TO CONFIRM IT IS A CURRENTLY 
*  IMPLEMENTED OPTION.
*
************************************************************************
      SUBROUTINE IMPCKP(IAC, *)
*
*  SPECIFICATIONS
*
      LOGICAL NONIMP
*
*  INITIALIZATIONS
*
      NONIMP= .FALSE.
* 
*  NACA 4-DIGIT SERIES
*
         IF(IAC .EQ. 1) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA MODIFIED 4-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 2) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 6-SERIES
*
         ELSE IF(IAC .EQ. 3) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 6A-SERIES
*
         ELSE IF(IAC .EQ. 4) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 16-SERIES
*
         ELSE IF(IAC .EQ. 5) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 6) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
* 
*  NACA MODIFIED 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 7) THEN
c        CALL MESSGE('T-ERROR/ OPTION NOT CURRENTLY IMPLIMENTED')
c        NONIMP= .TRUE.
         ENDIF
*
*  ROUTINE -IMPCKP- COMPLETE 
* 
         IF(NONIMP) THEN
         RETURN 1
         ELSE
         RETURN
         ENDIF
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 05 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ISSUER  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          CALLS... CHAR(INTRINSIC) NDCH WAITT.
C          UNITS... "DEFAULT OUTPUT".
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  Issue error message to screen indicating valid responce for request type.
*
************************************************************************
      SUBROUTINE ISSUER(TEXT, NDX1, NUMOPS, TYP) 
* 
*  SPECIFICATIONS 
* 
      CHARACTER CHAR*1
      INTEGER*4 NDCH
*
      CHARACTER*(*) TEXT, TYP*3 
      INTEGER*4 NDX1, NUMOPS
* 
*  ISSUE ERROR MESSAGE
* 
      WRITE(*,1000) TEXT(:NDCH(TEXT))
 1000 FORMAT(//,T11,'ERROR:   INVALID RESPONSE OF >',A,'<')
* 
*  INDICATE THE VALID SELECTION TYPE RESPONSE 
* 
         IF(TYP .EQ. 'SEL') THEN
         WRITE(*,1100) NDX1, NDX1+NUMOPS-1
 1100    FORMAT(
     .   T20,'SELECTION RESTRICTED TO <_> OR ',I2.2,' THRU ',I2.2,'.',/)
* 
*  INDICATE THE VALID ANSWER TYPE RESPONSE
* 
         ELSE IF(TYP .EQ. 'ANS') THEN 
         WRITE(*,1200)
 1200    FORMAT(
     .   T20,'SELECTION RESTRICTED TO <_> OR ANSWER IN PROPER FORM.',/) 
* 
*  INDICATE THE VALID LOGICAL TYPE RESPONSE 
* 
         ELSE IF(TYP .EQ. 'LOG') THEN 
         WRITE(*,1300) CHAR(NDX1), CHAR(NUMOPS) 
 1300    FORMAT(T20,'SELECTION RESTRICTED TO <_> OR ',A,' / ',A,'.',/)
         ENDIF
* 
*  DELAY FOR INFORMATION TO BE READ 
* 
      CALL WAITT(1.)
* 
*  ROUTINE -ISSUER- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 27 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE LIMITS  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE LIMITS(TEXT, LIMSTR) 
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) LIMSTR, TEXT
* 
*  ISSUE ERROR MESSAGE
* 
      WRITE(*,1000) TEXT(:NDCH(TEXT))
 1000 FORMAT(//,T11,'ERROR:   INVALID RESPONSE OF >',A,'<')
* 
*  INDICATE THE VALID SELECTION TYPE RESPONSE 
* 
      WRITE(*,1100) LIMSTR
 1100 FORMAT(T20,'SELECTION RESTRICTED TO <_> OR ',A,'.',/)
* 
*  DELAY FOR INFORMATION TO BE READ 
* 
      CALL WAITT(1.)
* 
*  ROUTINE -LIMITS- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 28 OCT 87, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION LKSTR       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      INTEGER*4 FUNCTION LKSTR(STR, TEXT)
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) STR, TEXT
* 
*  INITIALIZATIONS
* 
      I= NDCH(TEXT)
      J= NDCH(STR)
      LKSTR= 0
*
*  TEST FOR AN EMPTY SEARCH STRING
*
      IF(J .EQ. 0) GO TO 999
* 
*  SEARCH FOR FIRST CHARACTER OF STRING IN TEXT
* 
         DO 20 II= 1,I
            IF(TEXT(II:II) .EQ. STR(1:1)) THEN 
            IF(II+J-1 .GT. I) GO TO 999
*
*  TEST FOR REMAINDER OF STRING AT PRESENT LOCATION IN TEXT
*
               DO 10 JJ= 2,J
 10            IF(TEXT(II+JJ-1:II+JJ-1) .NE. STR(JJ:JJ)) GO TO 20
*
*  ASSIGN LOCATION IN TEXT THAT STRING WAS FOUND
*
            LKSTR= II
            GO TO 999
            ENDIF 
 20      CONTINUE 
* 
*  ROUTINE -LKSTR- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 11 DEC 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE MESSGE  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE MESSGE(TEXT) 
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) TEXT
      CHARACTER*(50) TMESS
* 
*  ISSUE MESSAGE
* 
      WRITE(*,'(//,T11,A)') TEXT(:NDCH(TEXT))
*
*  IF ERROR MESSAGE, PROCESS FOR THAT LEVEL
*
         IF(TEXT(2:7) .EQ. '-ERROR') THEN
*
*  FATAL ERROR
*
            IF(TEXT(:1) .EQ. 'F') THEN
            STOP    '         PROGRAM TERMINATION - FATAL ERROR' 
*
*  TRIVIAL ERROR
*
            ELSE IF(TEXT(:1) .EQ. 'T') THEN
            TMESS= '          PROGRAM INTERRUPTION - TRIVIAL ERROR'
            WRITE(*,'(A)') TMESS
            GO TO 999
*
*  DIAGNOSIS ERROR
*
            ELSE IF(TEXT(:1) .EQ. 'D') THEN
            STOP    '         ANALYST TERMINATION - DIAGNOSIS ERROR' 
*
*  WARNING ERROR
*
            ELSE IF(TEXT(:1) .EQ. 'W') THEN
            TMESS= '          ANALYST INTERRUPTION - WARNING ERROR' 
            WRITE(*,'(A)') TMESS
*
*  UNKNOWN ERROR LEVEL
*
            ELSE
            STOP    '         PROGRAM TERMINATION - UNKNOWN ERROR LEVEL' 
            ENDIF
         ENDIF
* 
*  DELAY FOR INFORMATION TO BE READ 
* 
 999  CALL WAITT(1.)
*
*  ROUTINE -MESSGE- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 27 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ML2D   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE ML2D(I,
     +                F, TANTH, THP, YCMB)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
      XSQ= X(I) * X(I)
      V1= 2. * CMY
* 
*  FOR X/C = 0 TO X/C = m, CALCULATE THE DEPENDENT VARIABLES
* 
         IF(.NOT. (X(I) .GT. CMY)) THEN
         CMYSQ= CMY * CMY
         V2= CMB / CMYSQ
         V3= 0.
*
*  FOR X/C > m TO X/C = 1, CALCULATE THE DEPENDENT VARIABLES
*
         ELSE
         OMCMY= 1. - CMY
         OMCMSQ= OMCMY * OMCMY
         V2= CMB / OMCMSQ
         V3= (1. - V1)
         ENDIF
*
*  CALCULATE Y CAMBER, TANGENT OF THETA, SECANT
*  OF THETA AND THE FIRST DERIVATIVE OF THETA
*
      YCMB= V2 * (V3 + (V1 * X(I)) - XSQ)
      TANTH= V2 * (V1 - (2. * X(I)))
      F= CALF(TANTH, FSQ)
      THP= V2 * (-2. / FSQ)
*
*  ROUTINE -ML2D- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 27 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ML3D   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE ML3D(I,
     +                F, TANTH, THP, YCMB)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
      V1= (1. / 6.) * CMB
* 
*  FOR X/C = 0 TO X/C = r, CALCULATE THE DEPENDENT VARIABLES
* 
         IF(.NOT. (X(I) .GT. CMY)) THEN
         CMYSQ= CMY * CMY
         XSQ= X(I) * X(I)
         XCU= XSQ * X(I)
         V2= 3. * CMY
         V3= CMYSQ * (3. - CMY)
*
*  CALCULATE Y CAMBER, TANGENT OF THETA, SECANT
*  OF THETA AND THE FIRST DERIVATIVE OF THETA
*
         YCMB= V1 * (XCU - (V2 * XSQ) + (V3 * X(I)))
         TANTH= V1 * ((3. * XSQ) - (2. * V2 * X(I)) + V3)
         F= CALF(TANTH, FSQ)
         THP= CMB * ((X(I) - CMY) / FSQ)
*
*  FOR X/C > r TO X/C = 1, CALCULATE THE DEPENDENT VARIABLES
*
         ELSE
         CMYCU= CMY * CMY * CMY
         V2= V1 * CMYCU
*
*  CALCULATE Y CAMBER, TANGENT OF THETA, SECANT
*  OF THETA AND THE FIRST DERIVATIVE OF THETA
*
         YCMB= V2 * (1. - X(I))
         TANTH= V2 * (-1.)
         F= CALF(TANTH, FSQ)
         THP= 0.0
         ENDIF
*
*  ROUTINE -ML3D- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 27 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ML3DR   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE ML3DR(I,
     +                 F, TANTH, THP, YCMB)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
      OMCMY= 1. - CMY
      OMCMCU= OMCMY * OMCMY * OMCMY
      XMCMY= X(I) - CMY
      XMCMSQ= XMCMY * XMCMY
      V1= (1. / 6.) * CMB
      V2= XMCMSQ * XMCMY
      V3= 3. * XMCMSQ
      V4= 3. * 2. * XMCMY
      V5= RK2OK1 * OMCMCU
      V6= V5 * X(I)
      V7= CMY * CMY * CMY
      V8= V7 * X(I)
* 
*  FOR X/C = 0 TO X/C = r
* 
         IF(.NOT. (X(I) .GT. CMY)) THEN
*
*  FOR X/C > r TO X/C = 1, CALCULATE THE DEPENDENT VARIABLES
*
         ELSE
         V2= RK2OK1 * V2
         V3= RK2OK1 * V3
         V4= RK2OK1 * V4
         ENDIF
*
*  CALCULATE Y CAMBER, TANGENT OF THETA, SECANT
*  OF THETA AND THE FIRST DERIVATIVE OF THETA
*
      YCMB= V1 * (V2 - V6 - V8 + V7)
      TANTH= V1 * (V3 - V5 - V7)
      F= CALF(TANTH, FSQ)
      THP= V1 * (V4 / FSQ)
*
*  ROUTINE -ML3DR- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, dd DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ML6S   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
c  note::: If the effort was available this entire routine should be
c          efficienty rewritten from the research notes for this task.
c          Due to the lack of manpower this has not been done, instead
c          the original dressed up code has been used.           -dws-
************************************************************************
      SUBROUTINE ML6S(I,
     +                F, TANTH, THP, YCMB)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
      big= 10.**10
      pi= 3.141592654 
      zero= .1**6 
c 
      ttanth= 0.0
      tycmb= 0.0
      tycp2= 0.0
c
         DO 500 J= 1,CMBNMR
         ai= a(j)
         amx= ai-x(i)
         oma= 1.-ai
         omx= 1.-x(i)
************************************************************************
c
c  calculate cambered airfoil parameters ycmb, tanth, f, thp at initial x
c
            if(i .eq. 1) then
            u= 0.005 
            omxl= omx*alog(omx) 
            omxl1= -alog(omx)-1. 
c  a = 1 and x = 0
               if(abs(ai-1.) .lt. zero) then
               h= 0.0 
               q= 0.0 
               z1= -omxl1 
c  a = 0 and x = 0
               else if(ai .lt. zero) then
               h= -.5 
               q= 1.0  
               z1= u*alog(u)-.5*u-.5*omx*omxl1+.5*omxl-.5
c  a = other and x = 0
               else
               g= -(ai**2*(.5*alog(ai)-0.25)+0.25)/oma 
               h= (.5*oma**2*alog(oma)-.25*oma**2)/oma+g
               q= 1.0 
               v= -amx/abs(amx) 
               amxl= amx*alog(abs(amx))
               amxl1= -alog(abs(amx))+v
               z1= .5*(amx*amxl1-amxl-omx*omxl1+omxl+amx-omx) 
               endif
c
            tycmb= 0.0
            tanth= cli(j)*(z1/(1.-q*ai)-1.-alog(u)-h)/pi/(ai+1.)/2.0 
            ttanth= ttanth + tanth
            tycp2= 0.0
************************************************************************
c
c  calculate cambered airfoil parameters ycmb, tanth, f, thp
c
            else
            u= x(i)
            xll= u*alog(u) 
c  a = 1 and x = 1
               if(abs(oma) .lt. zero .and. abs(omx) .lt. zero) then
               g= 0.0 
               h= 0.0 
               q= 0.0 
               z= 0.0
               z1= -big 
               z2= -big 
c  a = 0 and x = 1
               else if(ai .lt. zero .and. omx .lt. zero) then
               g= -.25 
               h= -.5 
               q= 1.0 
               z= -.25 
               z1= 0.0   
               z2= -big 
c  a = other and x = 1
               else if(abs(omx) .lt. zero) then
               g= -(ai**2*(.5*alog(ai)-0.25)+0.25)/oma 
               h= (.5*oma**2*alog(oma)-.25*oma**2)/oma+g
               q= 1.0 
               z= .5*(ai-1.)**2*alog(abs(ai-1.))-0.25*(ai-1.)**2 
               z1= -(ai-1.)* alog(abs(ai-1.)) 
               z2= -big 
c  a = x
               else if(abs(amx) .lt. zero) then
               g= -(ai**2*(.5*alog(ai)-0.25)+0.25)/oma 
               h= (.5*oma**2*alog(oma)-.25*oma**2)/oma+g
               q= 1.0 
               z= -.5*omx**2*alog(omx)+0.25*omx**2 
               z1= -.5*omx*(-alog(omx)-1.)+.5*omx*alog(omx)-.5*omx 
               z2= -alog(omx)-0.5
c  a = 1 and x = other
               else if(abs(ai-1.) .lt. zero) then
               g= 0.0 
               h= 0.0 
               q= 0.0 
               z= -omx*alog(omx)
               z1= alog(omx)+1. 
               z2= -1./omx 
c
               else
               v= -amx/abs(amx) 
               omxl= omx*alog(omx) 
               amxl= amx*alog(abs(amx))
               omxl1= -alog(omx)-1. 
               amxl1= -alog(abs(amx))+v
               omxl2= 1./omx 
               amxl2= 1./amx
c  a = 0 and x = other
                  if(ai .le. zero) then
                  g= -.25 
                  h= -.5 
                  q= 1.0 
c  a = other and x = other
                  else
                  g= -(ai**2*(.5*alog(ai)-0.25)+0.25)/oma
                  h= (.5*oma**2*alog(oma)-.25*oma**2)/oma+g
                  q= 1.0 
                  endif
               z= .5*amx*amxl-.5*omx*omxl+.25*omx**2-.25*amx**2 
               z1= .5*(amx*amxl1-amxl-omx*omxl1+omxl+amx-omx) 
               z2= .5*amx*amxl2-amxl1-.5*omx*omxl2+omxl1 
               endif
c
c  calculate ycmb for present camber line
c
            ycmb= cli(j)*(z/(1.-q*ai)-xll+g-h*u)/pi/(ai+1.)/2. 
c
c  calculate ycp2 and tanth for present camber line
c
               if(x(i) .le. 0.005) then
               u= 0.005
               ycp2= 0.0 
               else
               u= x(i)
c  x = 1
                  if(abs(omx) .eq. zero) then
                  ycp2= 1./zero 
c  x = other
                  else
                  ycp2= cli(j)*(z2/(1.-q*ai)-1./x(i))/(2.*pi*(ai+1.))
                  endif
               endif
            tanth= cli(j)*(z1/(1.-q*ai)-1.-alog(u)-h)/pi/(ai+1.)/2.0 
c
c  adjustments for 6a-series camber
c
               if(mlc .eq. 5)  then
               ycmb= ycmb * 0.97948 
               ycp2= ycp2 * 0.97948 
               tanth= tanth * 0.97948 
c
c  trailing edge adjustments for 6a-series camber
c  when camber line chordwise loading is 0.80
c
               clfact= .24521 * cli(j)
                  if(abs(ai-.8) .lt. zero .and. tanth .le. -clfact) then
                  ycmb= clfact * omx
                  ycp2= 0.0 
                  tanth= -clfact
                  endif
               endif
c
c  sum the camber parameters
c
            tycmb= tycmb + ycmb
            ttanth= ttanth + tanth
            tycp2= tycp2 + ycp2
            endif
 500     CONTINUE
c 
      ycmb= tycmb 
      tanth= ttanth
      ycp2= tycp2
c 
      f= sqrt(1. + tanth**2) 
      thp= ycp2 / f**2 
*
*  ROUTINE -ML6S- COMPLETE 
* 
      RETURN
      END 


CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 14 JAN 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE MLINP
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  INPUT THE REQUIRED MEAN LINE DATA.
*
************************************************************************
      SUBROUTINE MLINP
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'afdesc.h'
      INCLUDE 'chstg.h'
      INCLUDE 'lists.h'
*
      CHARACTER LINE*80, RDNTCK*80, TYP*3
      LOGICAL F, T
* 
*          INITIALIZATIONS
* 
      F= .FALSE.
      T= .TRUE.
* 
*  PROCESS MEAN LINE CODE, WHICH INCLUDE MLC EQUAL TO;
*               1    2    3    4    5    
************************************************************************
* 
*  NACA 2-DIGIT
*
         IF(MLC .EQ. 1) THEN
         DESIGC= '2-DIGIT'
*
*  INQUIRE ABOUT MAXIMUM ORDINATE TO CHORD RATIO
*
 100     LINE= RDNTCK(ADVC14(22), CUES2(7), F, ' ', 'R', nouse, CMB)
            IF(CMB .LT. 0. .OR. CMB .GT. 1.) THEN
            CALL LIMITS(LINE, '[0 .ge. CMB .le. 1]')
            GO TO 100
            ENDIF
*
*  INQUIRE ABOUT MAXIMUM LOCATION CAMBER
*
 200     LINE= RDNTCK(ADVC14(25), CUES2(8), F, ' ', 'R', nouse, CMY)
            IF(CMY .LT. 0. .OR. CMY .GE. 1.) THEN
            CALL LIMITS(LINE, '[0 .ge. XMT .lt. 1]')
            GO TO 200
            ENDIF
************************************************************************
* 
*  NACA 3-DIGIT
*
         ELSE IF(MLC .EQ. 2) THEN
         DESIGC= '3-DIGIT'
* 
*  INQUIRE ABOUT THE MEAN LINE DESIGNATION
* 
         NDX1= 1
         NUMOPS= 5
         TYP= 'SEL'
         MLD= NQUIRY(ADVIC9, CUES1(9), LIST9, NDX1, NUMOPS, TYP) 
* 
*  PROCESS INTEGER MEAN LINE DESIGNATION, WHICH INCLUDE MLD EQUAL TO;
*                  1    2    3    4    5    
*  ASSIGN MAXIMUM ORDINATE TO CHORD RATIO
*  AND MAXIMUM LOCATION CAMBER
*
            IF(MLD .EQ. 1) THEN
            CMB= 361.400
            CMY= .0580
*
            ELSE IF(MLD .EQ. 2) THEN
            CMB= 51.640
            CMY= .1260
*
            ELSE IF(MLD .EQ. 3) THEN
            CMB= 15.957
            CMY= .2025
*
            ELSE IF(MLD .EQ. 4) THEN
            CMB= 6.643
            CMY= .2900
*
            ELSE IF(MLD .EQ. 5) THEN
            CMB= 3.230
            CMY= .3910
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
            ELSE
        CALL MESSGE('D-ERROR/ INVALID MEAN LINE DESIGNATION /SUB MLINP')
            ENDIF
************************************************************************
* 
*  NACA 3-DIGIT REFLEX
*
         ELSE IF(MLC .EQ. 3) THEN
         DESIGC= '3-DIGIT REF'
* 
*  INQUIRE ABOUT THE MEAN LINE DESIGNATION
* 
         NDX1= 1
         NUMOPS= 4
         TYP= 'SEL'
         MLD= NQUIRY(ADVC10, CUES1(10), LIST10, NDX1, NUMOPS, TYP) 
* 
*  PROCESS INTEGER MEAN LINE DESIGNATION, WHICH INCLUDE MLD EQUAL TO;
*                  1    2    3    4        
*  ASSIGN MAXIMUM ORDINATE TO CHORD RATIO, 
*  MAXIMUM LOCATION CAMBER AND VALUE OF RATIO K2/K1
*
            IF(MLD .EQ. 1) THEN
            CMB= 51.990
            CMY= .1300
            RK2OK1= .000764
*
            ELSE IF(MLD .EQ. 2) THEN
            CMB= 15.793
            CMY= .2170
            RK2OK1= .00677
*
            ELSE IF(MLD .EQ. 3) THEN
            CMB= 6.520
            CMY= .3180
            RK2OK1= .0303
*
            ELSE IF(MLD .EQ. 4) THEN
            CMB= 3.191
            CMY= .4410
            RK2OK1= .1355
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
            ELSE
        CALL MESSGE('D-ERROR/ INVALID MEAN LINE DESIGNATION /SUB MLINP')
            ENDIF
************************************************************************
* 
*  NACA 6-SERIES
*
         ELSE IF(MLC .EQ. 4) THEN
         DESIGC= '6-SERIES'
*
*  INQUIRE ABOUT NUMBER OF CAMBER LINES
*
 401     LINE= RDNTCK(ADVC14(29),CUES2(9),T,'1','I',CMBNMR,unused)
            IF(CMBNMR .GT. 10) THEN
            CALL LIMITS(LINE, '[CMBNMR .le. 10]')
            GO TO 401
            ENDIF
*
            DO 450 I= 1,CMBNMR
*
*  INQUIRE ABOUT DESIGN LIFT COEFFICIENT
*
            LINE= RDNTCK(ADVC14(31),CUES2(10),F,' ','R',nouse,CLI(I))
*
*  IF FOR OTHER THAN 16-SERIES AIRFOIL SECTION,
*  INQUIRE ABOUT CHORDWISE LOADING
*
               IF(IAC .EQ. 5) THEN
               A(I)= 1.
               ELSE
 425           LINE= RDNTCK(ADVC14(34),CUES2(11),F,' ','R',nouse,A(I))
                  IF(A(I) .LT. 0. .OR. A(I) .GT. 1.) THEN
                  CALL LIMITS(LINE, '[0 .ge. A(I) .le. 1]')
                  GO TO 425
                  ENDIF
               ENDIF
 450        CONTINUE
************************************************************************
* 
*  NACA 6A-SERIES
*
         ELSE IF(MLC .EQ. 5) THEN
         DESIGC= '6A-SERIES'
*
*  INQUIRE ABOUT NUMBER OF CAMBER LINES
*
 501     LINE= RDNTCK(ADVC14(29),CUES2(9),T,'1','I',CMBNMR,unused) 
            IF(CMBNMR .GT. 10) THEN
            CALL LIMITS(LINE, '[CMBNMR .le. 10]')
            GO TO 501
            ENDIF
*
            DO 550 I= 1,CMBNMR
*
*  INQUIRE ABOUT DESIGN LIFT COEFFICIENT
*
            LINE= RDNTCK(ADVC14(31),CUES2(10),F,' ','R',nouse,CLI(I))
*
*  ASSIGN CHORDWISE LOADING
*
            A(I)= .80
 550        CONTINUE
************************************************************************
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
         ELSE
         CALL MESSGE('D-ERROR/ INVALID MEAN LINE CODE /SUB MLINP')
         ENDIF
************************************************************************
*  
*  ROUTINE -MLINP- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 03 OCT 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION NDCH      
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      INTEGER*4 FUNCTION NDCH(CHSTR) 
* 
*  SPECIFICATIONS 
* 
      CHARACTER CHSTR*(*) 
* 
*  LOCATE FIRST NON-BLANK TRAILING CHARACTER IN STRING
* 
         DO 50 NDCH= LEN(CHSTR),1,-1 
 50      IF(CHSTR(NDCH:NDCH) .NE. ' ') GO TO 999
* 
*  ASSIGN LENGTH IF BLANK STRING
* 
      NDCH= 0
* 
*  ROUTINE -NDCH- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 03 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION NOBK       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          CALLS... LEN(INTRINSIC).
C          CHSTR PARAMETER MUST BE PASSED WITH A DEFINED VARIABLE.
C          CHSTR PARAMETER USED TO RETURN COMPRESSED CHARACTER STRING.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  Number of non-blank characters after striping string of blanks.
*
************************************************************************
      INTEGER*4 FUNCTION NOBK(CHSTR)
* 
*  SPECIFICATIONS 
* 
      INTEGER*4 LEN
* 
      CHARACTER*(*) CHSTR 
*
      INTEGER*4 LENGTH
* 
*  INITIALIZATIONS
* 
      LENGTH= LEN(CHSTR)
      NOBK= 0 
* 
*  REMOVE BLANKS FROM TEXT STRING AND COUNT NON-BLANK CHARACTERS
* 
         DO 50 I= 1,LENGTH
            IF(CHSTR(I:I) .NE. ' ') THEN 
            NOBK= NOBK + 1
            CHSTR(NOBK:NOBK)= CHSTR(I:I)
            ENDIF 
 50      CONTINUE 
* 
*  REFILL STRING WITH TRAILING BLANKS 
* 
      CHSTR(NOBK+1:LENGTH)= ' '
* 
*  ROUTINE -NOBK- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 18 AUG 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION NQUIRY     
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      INTEGER*4 FUNCTION NQUIRY(ADVIC, CUE, LIST, NDX1, NUMOPS, TYP) 
* 
*  SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
      CHARACTER*(*) ADVIC(*), CUE, LIST(*), TYP*3
      CHARACTER*80 LINE, RDNTRY
* 
*  CLEAR TERMINAL SCREEN
* 
 100  CALL CLRSC
* 
*  PRINT MENU 
* 
      CALL BANNER 
      CALL SHMENU(CUE, LIST, NDX1, NUMOPS, TYP) 
* 
*  RECEIVE RESPONSE FROM USER 
* 
      LINE= RDNTRY('SELECTION', NDX1, NUMOPS, TYP) 
      CALL ICHK(ADVIC, LINE, NDX1, NUMOPS, TYP, *100, *100, *999) 
* 
      NQUIRY= IOP
* 
*  ROUTINE -NQUIRY- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 11 SEP 87, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION NQURY1    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      INTEGER*4 FUNCTION NQURY1(ADVIC, CUE, LIST, NDX1, NUMOPS, TYP) 
* 
*          SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
      CHARACTER*(*) ADVIC(*), CUE, LIST(*), TYP*3
      CHARACTER*80 LINE, RDNTRY
* 
*          CLEAR TERMINAL SCREEN
* 
 100  CALL CLRSC
* 
*          PRINT MENU 
* 
      CALL BANNER 
      CALL SHMENU(CUE, LIST, NDX1, NUMOPS, TYP) 
* 
*          RECEIVE RESPONSE FROM USER 
* 
      LINE= RDNTRY('SELECTION', NDX1, NUMOPS, TYP) 
      CALL ICHK1(ADVIC, LINE, NDX1, NUMOPS, TYP, *100, *100, *999) 
* 
*  ROUTINE -NQURY1- COMPLETE 
* 
 999  NQURY1= IOP
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 12 JUN 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE NTRP   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NTRP PERFORMS ONLY SECOND ORDER INTERPOLATIONS.
C          VARI ARRANGED BY STRICTLY INCREASING OR DECREASING MAGNITUDE.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          ???-07JUL68-EXTRACTED FROM MATH LIB. FOR USE IN PROGRAM LADSON.
C          DWS-12JUN91-CLEANED UP AND STANDARDIZED FOR PROGRAM AIRFOLS.
C          DWS-06MAR92-ERROR MESSAGE ADDED FOR ILLEGAL ARGUMENT RECEIVED.
C          DWS-20FEB95-REPLACED INTERPOLATION METHOD WITH SPLIN FROM C.BROOKS.
C          DWS-12MAR96-CORRECTED ISIZ VALUE; STORAGE REQUIREMENT = MAX. NP + 4.
C          DWS-18MAR96-CORRECTED STORAGE LOOP INDEXING; 3,NP CHANGED TO 3,NP+2.
************************************************************************
*
*  THE ORIGINAL ROUTINE SPLIN CAME FROM THE FORTRAN MATH LIBRARY USED ON THE
*  NASA LANGLEY CYBERS WITH NOS.  THE SUBROUTINE SPLIN EMPLOYS THE METHOD OF
*  INTERPOLATION DEVELOPED AND PUBLISHED BY H.AKIMA IN VOL. 7, NO. 4, OCTOBER
*  1970, PP. 589-602 OF THE "Journal of the Association for Computing Machinery".
*  THE FITTED CURVE IS DEFINED AS A PIECEWISE CUBIC HAVING CONTINUOUS FUNCTION 
*  AND FIRST DERIVATIVES BASED ON A LOCAL METHOD WHICH COMPUTES A SLOPE AT ANY 
*  GIVEN POINT ON THE BASIS OF THAT POINT AND ITS TWO ADJACENT LEFT AND RIGHT 
*  NEIGHBORS (WHICH, IN THE CASE OF EXTREME LEFT OR RIGHT EVALUATION POINTS OR 
*  THEIR NEIGHBORS, ARE DEFINED TO THE LEFT OR RIGHT OF THE EVALUATION POINT AS 
*  EXTRAPOLATIONS OF THE GIVEN DATA POINTS).  THE RESULTING CURVE MORE CLOSELY
*  MATCHES THE MANUALLY DRAWN CURVE FITS OF EXPERIENCED PERSONS THAN THE 
*  ALTERNATIVE "OSCULATORY" LOCALLY DEFINED PIECEWISE C1 CONTINUOUS CURVE, WHILE 
*  AVOIDING THE EXTRANEOUS OSCILLATIONS OF GLOBAL METHODS OF HIGHER CONTINUITY 
*  (SUCH AS SPLINES).  THE FUNCTION PRESUMES STRICT MONITONICITY OF THE
*  INDEPENDENT VARIABLE.
*
*  SUBROUTINE SPLIN (   XX, YY, Z, F, N1, N)  {N1 hardwired to 1 for this app.}
*  SUBROUTINE NTRP  (N, XX, YY, Z, F)
*
*  SUBROUTINE AKISPL (SPLIN) FITS A SMOOTH CURVE TO A GIVEN SET OF DATA POINTS.
*  ITS USAGE FOR INTERPOLATION REQUIRES THE SPECIFICATION OF THE DATA POINTS 
*  XX(L), YY(L) FOR L=1,NP AND THE FUNCTION VALUE Z TO BE DETERMINED.  THE VALUE 
*  F CONTAINS THE INTERPOLATED DATA.
************************************************************************
*
*  NP   = INTEGER, THE NUMBER OF POINTS IN ARRAY OF VARIABLES
*  VARI = REAL ARRAY OF INDEPENDENT VARIABLE, X;  VARI(NP)
*  VARD = REAL ARRAY OF DEPENDENT VARIABLE, Y;  VARD(NP)
*  X    = REAL, INDEPENDENT VARIABLE VALUE TO INTERPOLATE AT
*  Y    = REAL, VALUE OF DEPENDENT VARIABLE AT X
*
************************************************************************
      SUBROUTINE NTRP(NP, VARI, VARD, X, Y)
*
*  SPECIFICATIONS
*
      PARAMETER (ISIZ= 201+4) 
*
      INTEGER*4 L, NP
      REAL*4 VARI(NP), VARD(NP), XVAR(ISIZ), YVAR(ISIZ)
      REAL*4 A(4,ISIZ), M(ISIZ)
      REAL*4 DM(ISIZ), DX(ISIZ), DY(ISIZ)
      REAL*4 Y, X, XL1, XL2, XR1, XR2
*
*  INITIALIZATIONS
*
         DO 100 L= 1,NP
         XVAR(L)= VARI(L)
         YVAR(L)= VARD(L)
100      CONTINUE
*
*  TEST PARAMETERS TO CONFORM TO FORMULA RESTRICTIONS
*
         IF(NP .GT. 2) THEN
*
*  CALCULATION OF ADDITIONAL DATA POINTS BEYOND THE INTERVAL VARI(1),VARI(N)
*
         XR1= XVAR(NP) - XVAR(NP-2) + XVAR(NP-1)
         XR2= 2. * XVAR(NP) - XVAR(NP-2)
*
*  LEFT EXTENSION
*
         XL1= 2. * XVAR(1) - XVAR(3)
         XL2= XVAR(1) - XVAR(3) + XVAR(2)
*
*  CALCULATION OF SLOPE
*
            DO 200 L= 2,NP
200         M(L)= (YVAR(L) - YVAR(L-1)) / (XVAR(L) - XVAR(L-1))
*
*  FUNCTION VALUES FOR THE TWO LEFTMOST POINTS
*
         YR1= (2. * M(NP) - M(NP-1)) * (XR1 - XVAR(NP)) + YVAR(NP)
         YR2= (2. * (YR1 - YVAR(NP)) / (XR1 - XVAR(NP)) - M(NP)) * 
     +        (XR2 - XR1) + YR1
*
*  FUNCTION VALUES FOR THE TWO RIGHT-MOST POINTS
*
         YL2= (2. * M(2) - M(3)) * (XL2 - XVAR(1)) + YVAR(1)
         YL1= (2. * (YVAR(1) - YL2)) / (XVAR(1) - XL2) - M(2) * 
     +        (XL1 - XL2) + YL2
*
*  STORAGE OF DATA POINTS IN ARRAYS XVAR AND YVAR
*
            DO 300 L= 3,NP+2
            DM(L)= M(L-2)
            DX(L)= XVAR(L-2)
            DY(L)= YVAR(L-2)
300         CONTINUE
*
            DO 400 L= 3,NP+2
            XVAR(L)= DX(L)
            YVAR(L)= DY(L)
            M(L)= DM(L)
400         CONTINUE
*
         XVAR(1)= XL1
         XVAR(2)= XL2
         XVAR(NP+3)= XR1
         XVAR(NP+4)= XR2

         YVAR(1)= YL1
         YVAR(2)= YL2
         YVAR(NP+3)= YR1
         YVAR(NP+4)= YR2
*
*  CALCULATION OF THE SLOPE FOR THE EXTRA DATA POINTS
*
            DO 500 L= 2,3
500         M(L)= (YVAR(L) - YVAR(L-1)) / (XVAR(L) - XVAR(L-1))
*
            DO 600 L= NP+3,NP+4
600         M(L)= (YVAR(L) - YVAR(L-1)) / (XVAR(L) - XVAR(L-1))
*
*  CALCULATION OF THE THIRD DEGREE POLYNOMIALS USED FOR INTERPOLATION
*
            DO 700 L= 2,NP+1
               IF(M(L) .NE. M(L+1)) THEN
                  IF(M(L+2) .NE. M(L+3)) THEN
                  DM(L-1)= ( ABS(M(L+3) - M(L+2)) * M(L+1) +
     +                       ABS(M(L+1) - M(L))   * M(L+2) ) / 
     +                     ( ABS(M(L+3) - M(L+2)) + ABS(M(L+1) - M(L)) )
                  ELSE
                  DM(L-1)= M(L+2)
                  ENDIF
               ELSE IF(M(L+2) .EQ. M(L+3)) THEN
               DM(L-1)= (M(L+1) + M(L+2)) / 2.
               ELSE
               DM(L-1)= M(L+1)
               ENDIF
700         CONTINUE
*
            DO 800 L= 1,NP-1
            A(1,L)= YVAR(L+2)
            A(2,L)= DM(L)
            A(3,L)= (3. * M(L+3) - 2. * DM(L) - DM(L+1)) / 
     +              (XVAR(L+3) - XVAR(L+2))
            A(4,L)= (DM(L) + DM(L+1) - 2. * M(L+3)) / 
     +              (XVAR(L+3) -XVAR(L+2))**2
800         CONTINUE
*
*  CALCULATION OF INTERPOLATED VALUES
*
         L= 1
         XS= X
*
925         CONTINUE
               IF(XS .LT. XVAR(L+2)) THEN
950               CONTINUE
                     IF(L .NE. 1) THEN
                     L= L-1
                        IF(XS .LT. XVAR(L+2)) THEN
                        GO TO 950
                        ENDIF
                     ENDIF
               ELSE
                  IF(L .NE. NP-1) THEN
                  L= L+1
                  GO TO 925
                  ENDIF
               ENDIF
*
         S= XS - XVAR(L+2)
         Y= ((A(4,L) * S + A(3,L)) * S + A(2,L)) * S + A(1,L)
*
*  RECEIVED INCORRECT PARAMETERS
*
         ELSE
         CALL MESSGE('D-ERROR/ INCORRECT ARGUMENT USAGE /SUB NTRP')
         ENDIF
*
*  ROUTINE -NTRP- COMPLETE
*
      RETURN
      END

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, dd mmm yy, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE OPNFIL   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE OPNFIL
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
*
      CHARACTER FILNAM*80
*
*  OPEN ORDINATE DATA FILE AND OUTPUT REPORT FILE
*
      FILNAM= PATH(:NDCH(PATH)) // '.aux'
      OPEN(IUA, FILE=FILNAM, ACCESS='DIRECT', RECL=8, STATUS='UNKNOWN')
*
      FILNAM= PATH(:NDCH(PATH)) // '.dta'
      OPEN(IUD, FILE=FILNAM, STATUS='UNKNOWN')
*
      FILNAM= PATH(:NDCH(PATH)) // '.rpt'
      OPEN(IUR, FILE=FILNAM, STATUS='UNKNOWN')
*
*  ROUTINE -OPNFIL- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 16 DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE PDESIG   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATES THE ORNINATES FOR A SPECIFIED THICKNESS DISTRIBUTION BY
*  PROCESSING THE INTEGER AIRFOIL CODE, IAC.
*
************************************************************************
      SUBROUTINE PDESIG(I, IAC)
* 
*  NACA 4-DIGIT SERIES
*
         IF(IAC .EQ. 1) THEN
         CALL TD4D(I)
* 
*  NACA MODIFIED 4-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 2) THEN
         CALL TDM4D(I)
* 
*  NACA 6-SERIES
*
         ELSE IF(IAC .EQ. 3) THEN
         CALL TD6S(I) 
* 
*  NACA 6A-SERIES
*
         ELSE IF(IAC .EQ. 4) THEN
         CALL TD6S(I) 
* 
*  NACA 16-SERIES
*
         ELSE IF(IAC .EQ. 5) THEN
         CALL TDM4D(I)
* 
*  NACA 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 6) THEN
         CALL TD4D(I) 
* 
*  NACA MODIFIED 5-DIGIT SERIES
*
         ELSE IF(IAC .EQ. 7) THEN
         CALL TDM4D(I)
* 
*  RECEIVED INTEGER CODE IN ERROR
* 
         ELSE
         CALL MESSGE('D-ERROR/ INVALID AIRFOIL CODE /SUB PDESIG')
         ENDIF
*
*  ROUTINE -PDESIG- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 24 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE PROFIL   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  CALCULATE ORNINATES FOR PROFILE OF SPECIFIED THICKNESS DISTRIBUTION.
*
************************************************************************
      SUBROUTINE PROFIL(I)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
*
*  CALCULATE ORNINATES FOR PROFILE OF SPECIFIED THICKNESS DISTRIBUTION
*
      CALL PDESIG(I, IAC)
*
*  DIMENSION TO THE MODEL CHORD LENGTH
*
      XC= X(I) * CHD
      YC= Y * CHD
*
*  ROUTINE -PROFIL- COMPLETE 
* 
      RETURN 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 02 JAN 87, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE PROMPT  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE PROMPT(TEXT)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'chstg.h'
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      INCLUDE 'lists.h'
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
*
      CHARACTER*(*) TEXT
      CHARACTER*80 ADVIC(4)*52, LINE, RDNTRY, TYP*3
* 
*  INITIALIZATIONS
* 
      ADVIC(1)= '3'
      ADVIC(2)= 'PROGRAM HAS BEEN PROMPTED FOR A PARTICULAR RESPONSE'
      ADVIC(3)= 'WHILE IN EXAMPLE MODE, THUS THIS MESSAGE IS RECEIVED'
      ADVIC(4)= 'INSTEAD OF THE RESPONSE SPECIFIED BEING PERFORMED'
      MPR= ITRUE
      NDX1= 1
      NULL= ICHAR(' ')
      NUMPR= 5
      TYP= 'SEL'
* 
*  INQUIRE ABOUT PROCESSING DESIRED IF IT HAS NOT BEEN SPECIFIED
* 
 99      IF((NDCH(TEXT) .EQ. 1) .OR. (IOP .EQ. 0)) THEN
         IOP= 0
*
*  TEST FOR PROMPT OPTION REENTERED
*
 100     IF(IOP .EQ. IOPSL) GO TO 99
* 
*  CLEAR TERMINAL SCREEN
* 
         CALL CLRSC
* 
*  PRINT MENU 
* 
         CALL BANNER 
         CALL SHMENU(CUES1(5), LIST5, NDX1, NUMPR, TYP) 
* 
*  RECEIVE RESPONSE FROM USER 
* 
         LINE= RDNTRY('SELECTION', NDX1, NUMPR, TYP) 
         TEXT= LINE
         CALL ICHK1(ADVIC5, LINE, NDX1, NUMPR, TYP, *100, *100, *999) 
         ENDIF
*
*  TEST FOR PROGRAM IN EXAMPLE MODE
*
         IF(MEX .EQ. ITRUE) THEN
         CALL XPLAIN(ADVIC, .TRUE.)
         GO TO 999
         ENDIF
*
*  CONVERT ENTRY TO ALL UPPER CASE
*
         DO 150 I= 1,NDCH(TEXT)
         IF(TEXT(I:I) .GE. 'a' .AND. TEXT(I:I) .LE. 'z')
     .   TEXT(I:I)= CHAR(ICHAR(TEXT(I:I))-32)
 150     CONTINUE
*
*  TEST FOR REQUEST OF EDIT PROCESS
*
         IF(TEXT(2:3) .EQ. 'ED' .OR. IOP .EQ. 1) THEN
         CALL MESSGE('W-ERROR/ PROCESS NOT IMPLEMENTED')
*
*  TEST FOR REQUEST OF EXAMPLE PROCESS
*
         ELSE IF(TEXT(2:3) .EQ. 'EX' .OR. IOP .EQ. 2) THEN
         CALL SHXAMP
*
*  TEST FOR REQUEST OF REPEAT PROCESS
*
         ELSE IF(TEXT(2:3) .EQ. 'RE' .OR. IOP .EQ. 3) THEN
         CALL MESSGE('W-ERROR/ PROCESS NOT IMPLEMENTED')
*
*  TEST FOR REQUEST OF RESTART PROCESS
*
         ELSE IF(TEXT(2:3) .EQ. 'RS' .OR. IOP .EQ. 4) THEN
         CALL CLSFIL
         CALL ADMIN
*
*  TEST FOR REQUEST OF VIEW PROCESS
*
         ELSE IF(TEXT(2:3) .EQ. 'VW' .OR. IOP .EQ. 6) THEN
         CALL MESSGE('W-ERROR/ PROCESS NOT IMPLEMENTED')
*
*  PROCESS REQUESTED WAS NOT VALID, ISSUE ERROR
*
         ELSE
         CALL ISSUER(TEXT, NULL, NULL, 'ANS')
         IOP= 0
         GO TO 99
         ENDIF
* 
*  ROUTINE -PROMPT- COMPLETE 
* 
 999  MPR= IFALSE
      IOP= IOPSL
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 22 OCT 87, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION RDNTCK    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-14FEB92-MODIFIED TO ACCEPT TYP=* AS FREE FORMAT REQUEST.
************************************************************************
*
*  READS AN ENTRY FROM INTERACTIVE INPUT AND CHECKS FOR TYPE REQUESTED;
*  PROVIDES PROVISIONS FOR A DEFAULT IF APPLICABLE.
*
************************************************************************
      CHARACTER*(*) FUNCTION RDNTCK(ADVIC, CUE, DFAULT, CVALDF, TYP,
     .                               IVAL, RVAL)
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) ADVIC(*), CVALDF, CUE, RDNTRY*80, TYP*1
      CHARACTER FORM*7
      LOGICAL DFAULT
* 
*  INITIALIZATIONS
* 
      NULL= ICHAR(' ')
* 
*  RECEIVE RESPONSE FROM USER AS TYPE CHARACTER ENTRY
* 
 10   RDNTCK= RDNTRY(CUE, 0, 0, 'ANS') 
* 
*  TEST FOR DEFAULT ACCEPTABLE AS A RESPONSE
* 
         IF(DFAULT) THEN
         CALL ICHK(ADVIC, RDNTCK, 0, 0, 'ANS', *20, *10, *999) 
 20      IF(RDNTCK .EQ. '<CR>') RDNTCK= CVALDF
*
*  DEFAULT IS NOT AN ACCEPTABLE RESPONSE
*
         ELSE
         CALL ICHK(ADVIC, RDNTCK, 0, 0, 'ANS', *10, *10, *999) 
         ENDIF
* 
*  TEST FOR TYPE INTEGER CONVERSION AND STORAGE REQUIREMENT
* 
         IF(TYP .EQ. 'I') THEN
            IF(LKSTR('.',RDNTCK) .GT. 0) THEN
            CALL ISSUER(RDNTCK, NULL, NULL, 'ANS') 
            GOTO 10
            ENDIF
         WRITE(FORM,'(''(I'',I2.2,'')'')') NDCH(RDNTCK)
         READ(RDNTCK,FORM,ERR=10) IVAL
* 
*  TEST FOR TYPE REAL CONVERSION AND STORAGE REQUIREMENT
*
         ELSE IF(TYP .EQ. 'R') THEN
            IF(LKSTR('.',RDNTCK) .EQ. 0) THEN
            CALL ISSUER(RDNTCK, NULL, NULL, 'ANS') 
            GOTO 10
            ENDIF
         WRITE(FORM,'(''(F'',I2.2,''.0)'')') NDCH(RDNTCK)
         READ(RDNTCK,FORM,ERR=10) RVAL
* 
*  TEST FOR TYPE FREE FORMAT CONVERSION AND STORAGE REQUIREMENT; REAL OR INTEGER
*
         ELSE IF(TYP .EQ. '*') THEN
            IF(LKSTR('.',RDNTCK) .EQ. 0) THEN
            TYP= 'I'
            WRITE(FORM,'(''(I'',I2.2,'')'')') NDCH(RDNTCK)
            READ(RDNTCK,FORM,ERR=10) IVAL
            ELSE
            TYP= 'R'
            WRITE(FORM,'(''(F'',I2.2,''.0)'')') NDCH(RDNTCK)
            READ(RDNTCK,FORM,ERR=10) RVAL
            ENDIF
         ENDIF
* 
*  ROUTINE -RDNTCK- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 31 OCT 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION RDNTRY    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          USES NEW-LINE SUPPRESSION CHARACTER SPECIFIC TO EACH PATHFORM.
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  PROMPS FOR AN ENTRY OF THE REQUESTED TYPE THEN READS FROM INTERACTIVE
*  INPUT.
*
************************************************************************
      CHARACTER*(*) FUNCTION RDNTRY(CUE, NDX1, NUMOPS, TYP)
* 
*  SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
      INCLUDE 'pssc.h'
* 
      CHARACTER CUE*(*), FORM*44, PCK(2)*1, STR*2, TYP*3
*
*  INITIALIZATIONS
* 
         IF(NLSCH .EQ. ' ') THEN
         STR= ' ' // NLSCH
         ELSE
         STR= ',' // NLSCH
         ENDIF
************************************************************************
* 
*  REQUEST A SELECTION TYPE ENTRY 
* 
         IF(TYP .EQ. 'SEL') THEN
         FORM= '(T16,''ENTER '',A,'' ('',I2.2,''-'',I2.2,'') > '',x)'
         WRITE(FORM(42:43),'(A2)') STR
         WRITE(*,FORM) CUE(:NDCH(CUE)), NDX1, NDX1+NUMOPS-1
************************************************************************
* 
*  REQUEST AN ANSWER TYPE ENTRY OR A PROGRAM CONTROL
* 
         ELSE IF(TYP .EQ. 'ANS' .OR. TYP .EQ. 'CNT') THEN 
         FORM= '(/,T16,''ENTER '',A,'' > '',x)'
         WRITE(FORM(24:25),'(A2)') STR
         WRITE(*,FORM) CUE(:NDCH(CUE)) 
************************************************************************
* 
*  REQUEST A LOGICAL TYPE ENTRY 
* 
         ELSE IF(TYP .EQ. 'LOG') THEN 
         PCK(1)= CHAR(NDX1) 
         PCK(2)= CHAR(NUMOPS) 
         FORM= '(T16,''ENTER '',A,'' ('',A,''/'',A,'') > '',x)'
         WRITE(FORM(36:37),'(A2)') STR
         WRITE(*,FORM) CUE(:NDCH(CUE)), (PCK(I), I=1,2)
         ENDIF
*
*  TEST FOR PROGRAM IN EXAMPLE MODE
*
         IF(MEX .NE. ITRUE) THEN
* 
*  RETRIEVE ENTRY; SEL, ANS/CNT, OR LOG TYPE
* 
         READ(*,'(A)',END=999,ERR=999,IOSTAT=IOS) RDNTRY
         ELSE
*
*  RETRIEVE ENTRY FROM ALTERNATE INPUT SOURCE
*
         READ(9,'(A)',END=999,ERR=999,IOSTAT=IOS) RDNTRY
*
*  WRITE ENTRY TO THE SCREEN
*
cdws     FORM= '(1H+,A,x)'
cdws     WRITE(FORM(7:8),'(A2)') STR
cdws     WRITE(*,FORM) RDNTRY(:(NDCH(RDNTRY)))
         WRITE(*,'(1H ,A)') RDNTRY(:(NDCH(RDNTRY)))
*
*  DELAY FOR USER TO SEE ANSWER
*
         CALL WAITT(1.)
	 ENDIF
************************************************************************
* 
*  ROUTINE -RDNTRY- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 01 APR 96, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE RESTRT   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  RESTARTS PROGRAM EXECUTION FROM THE BEGINNING OF A RUN.
*
************************************************************************
      SUBROUTINE RESTRT 
*
*  SPECIFICATIONS
*
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
*  CLEAR ANY OPEN FILES AND RESTART EXECUTION.
* 
      CALL CLSFIL
      CALL ADMIN    
*  
*  ROUTINE -RESTRT- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 14 NOV 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE SHCTRL  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  SHOW THE USER THE PROGRAM CONTROLS BY WRITING TO THE TERMINAL SCREEN.
*
************************************************************************
      SUBROUTINE SHCTRL
* 
*  WRITE PROGRAM CONTROLS TO THE SCREEN 
* 
      WRITE(*,1000) 
 1000 FORMAT(//,T11,'<Q>UIT, <E>XIT, <?> EXPLAIN, </> RESPOND, <CR>,',/)
* 
*  ROUTINE -SHCTRL- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 30 OCT 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE SHMENU   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE SHMENU(CUE, LIST, NDX1, NUMOPS, TYP) 
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) CUE, LIST(*), PCK(2)*1, TYP*3
*
*  SHOW PROGRAM CONTROLS
* 
      CALL SHCTRL
************************************************************************
* 
*  PRODUCE A SELECTION TYPE MENU
* 
         IF(TYP .EQ. 'SEL') THEN
         N= NUMOPS
         NDX= NDX1 - 1
* 
*  WRITE MENU CUE TO THE SCREEN 
* 
         WRITE(*,1101) CUE(:NDCH(CUE)) 
 1101    FORMAT(T11,A,' OPTIONS: ')
* 
*  WRITE MENU LIST TO THE SCREEN
* 
         WRITE(*,1102) (NDX+I, LIST(I)(:NDCH(LIST(I))), I=1,N) 
 1102    FORMAT(T16,I2.2,'.) ',A) 
         WRITE(*,'(1H )') 
************************************************************************
* 
*  PRODUCE A LOGICAL TYPE MENU
* 
         ELSE IF(TYP .EQ. 'LOG') THEN 
         PCK(1)= CHAR(NDX1) 
         PCK(2)= CHAR(NUMOPS) 
* 
*  WRITE MENU CUE TO THE SCREEN 
* 
         WRITE(*,1301) CUE(:NDCH(CUE)) 
 1301    FORMAT(T11,A,': ')
* 
*  WRITE MENU LIST TO THE SCREEN
* 
         WRITE(*,1302) (PCK(I), LIST(I)(:NDCH(LIST(I))), I=1,2)
 1302    FORMAT(T16,A,'.) ',A)
         WRITE(*,'(1H )') 
         ENDIF
************************************************************************
* 
*  ROUTINE -SHMENU- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 DEC 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE SHUTDW   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
************************************************************************
      SUBROUTINE SHUTDW 
* 
*  WRITE A SHUTDW MESSAGE TO THE SCREEN 
* 
      WRITE(*,9999) 
 9999 FORMAT(//,T21,'FINIS',/////) 
*  
*  ROUTINE -SHUTDW- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR: D.W. SPROLES, CSC, 09 MAR 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           FUNCTION SIGN       
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  C
*
************************************************************************
      REAL*4 FUNCTION SIGN(A1, A2)
* 
*  INITIALIZATIONS
* 
      A1ABS= ABS(A1)
* 
         IF(A2 .LT. 0) THEN
         SIGN= -A1ABS
         ELSE
         SIGN= A1ABS
         ENDIF
* 
*  ROUTINE -SIGN- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 28 FEB 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE SYSS   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  DEFINES THE TARGET PLATFORM FOR SYSTEM SPECIFIC CONFIGURATION BY 
*  PROMPTING THE USER WHEN NOT DEFINED PRIOR TO CODE COMPILATION.
*
*  PERFORM SYSTEM SPECIFIC CONFIGURATION AS FIRST OPERATIONS IN THE CODE.
* 
*  THE SUPPORTED DEVICES ARE: 
*  1. CONVEX C2 using CONVEX FORTRAN compiler         (CNVXC2) 
*  2. IBM compatible PC using IBM FORTRAN/2 compiler  (IBMPC) 
*  3. Sun-3 using Sun FORTRAN compiler                (SUN3) 
*  4. VAX 780 using VAX FORTRAN compiler              (VAX780) 
*  5. IRIS-4D using Silicon Graphics FORTRAN compiler (IRIS4D) 
*  6. Sun-4 using Sun FORTRAN compiler                (SUN4) 
*  7. Gateway 2000 PC using Lahey FORTRAN compiler    (GATEWAY) 
*  8. Generic; us only if other devices unavailable   (GENERIC) 
*
************************************************************************
      SUBROUTINE SYSS(IPDV)
* 
*  SPECIFICATIONS 
* 
      CHARACTER*50 ADVIC(1), CUES, DTAIL(3), LIST(8), TYP*3
* 
*  INITIALIZATIONS
* 
      DATA ADVIC(1)/ '0' /
      DATA CUES/ 'PLATFORM CONFIGURATION' /
      DATA DTAIL(1)/ '2' /
      DATA DTAIL(2)/ 'PRE-COMPILATION INSTRUCTION SPECIFING' /
      DATA DTAIL(3)/ 'SOFTWARE''S TARGET PLATFORM UNSATISFIED' /
      DATA LIST(01)/ 'CONVEX C2 using CONVEX FORTRAN compiler' /
      DATA LIST(02)/ 'IBM compatible PC using IBM FORTRAN/2 compiler' /
      DATA LIST(03)/ 'Sun-3 using Sun FORTRAN compiler' /
      DATA LIST(04)/ 'VAX 780 using VAX FORTRAN compiler' /
      DATA LIST(05)/ 'IRIS-4D using Silicon Graphics FORTRAN compiler' /
      DATA LIST(06)/ 'Sun-4 using Sun FORTRAN compiler' /
      DATA LIST(07)/ 'Gateway 2000 PC using Lahey FORTRAN compiler'/
      DATA LIST(08)/ 'Generic; us only if other devices unavailable' /
* 
      NDX1= 1
      NUMOPS= 8
      TYP= 'SEL'
*
*  WRITE UNSATISFIED INSTRUCTION MESSAGE
*
      CALL XPLAIN(DTAIL, .FALSE.)
* 
*  INQUIRE ABOUT THE PLATFORM DESCRIPTOR VARIABLE
* 
      IPDV= NQUIRY(ADVIC, CUES, LIST, NDX1, NUMOPS, TYP) 
*
*  ROUTINE -SYSS- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 16 DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE TD4D   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE TD4D(I)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
      A0=  0.2969
      A1= -0.1260
      A2= -0.3516
      A3=  0.2843
      A4= -0.1015
* 
      SRX= SQRT(X(I))
      XSQ= X(I) * X(I)
      XCU= XSQ * X(I)
      SRXCU= SQRT(XCU)
      XQU= XCU * X(I)
* 
*  CALCULATE THE LEADING EDGE RADIUS FROM A0 FOR PRINTING TO REPORT
* 
      RLE= ((A0 * TOC) / .2)**2 / 2.
* 
*  FOR THE PRESENT X (X/C), CALCULATE THICKNESS Y (Y/C)
* 
      V1= A0 * SRX
      V2= A1 * X(I)
      V3= A2 * XSQ
      V4= A3 * XCU
      V5= A4 * XQU
      Y= V1 + V2 + V3 + V4 + V5
* 
*  CALCULATE YP, THE FIRST DERIVATIVE OF Y
* 
         IF(SRX .GT. 0.) THEN
         V1= A0 * .5 * (1./SRX)
         V3= A2 * 2. * X(I)
         V4= A3 * 3. * XSQ
         V5= A4 * 4. * XCU
         YP= V1 + A1 + V3 + V4 + V5
         ELSE
         YP= 999.E20
         ENDIF
*
*  CALCULATE YPP, THE SECOND DERIVATIVE OF Y
* 
         IF(SRXCU .GT. 0.) THEN
         V1= A0 * .5 * .5 * (-1./SRXCU)
         V3= A2 * 2. * 1.
         V4= A3 * 3. * 2. * X(I)
         V5= A4 * 4. * 3. * XSQ
         YPP= V1 + 0. + V3 + V4 + V5
         ELSE
         YPP= -999.E20
         ENDIF
*
*  ADJUST FROM THE STANDARD .20 TO THE DESIRED THICKNESS TO CHORD RATIO
*
      Y= Y * TOC / .20
      YP= YP * TOC / .20
      YPP= YPP * TOC / .20
*
*
*  ROUTINE -TD4D- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 06 MAR 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE TD6S
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE TD6S(I)
*
*  SPECIFICATIONS 
* 
      INCLUDE 'af6s.h'
      INCLUDE 'afdesc.h'
* 
*  FOR THE PRESENT X (X/C), INTERPOLATE THICKNESS Y (Y/C)
* 
      CALL NTRP (NP, XT, YT, X(I), Y)
* 
*  INTERPOLATE YP, THE FIRST DERIVATIVE OF Y
* 
      CALL NTRP (NP, XT, YTP, X(I), YP)
*
*  INTERPOLATE YPP, THE SECOND DERIVATIVE OF Y
* 
      CALL NTRP (NP, XT, YTPP, X(I), YPP)
*
*  ROUTINE -TD6S- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 16 DEC 91, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE TDM4D   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE TDM4D(I)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
* 
*  INITIALIZATIONS
* 
         IF(I .EQ. 1) THEN
*
*  CALCULATE THE "A" CONSTANTS ON THE FIRST PASS
*
         SR2RLE= SQRT(2. * RLE)
         A0= SR2RLE * .20 / TOC
         A3= CALA3(A0, D1, XMT)
         A2= CALA2(A0, A3, XMT)
         A1= CALA1(A0, A2, A3, XMT)
*
*  CALCULATE THE "D" CONSTANTS ON THE FIRST PASS
*
         OMXMT= 1. - XMT
         OMXMSQ= OMXMT * OMXMT
         D3= ((3. * D1) - (.588 / OMXMT)) / (3. * OMXMSQ)
         D2= (-1.5 * OMXMT * D3) - ((.5 * D1) / OMXMT)
         D0= .002
*
*  CALCULATE THE RADIUS OF CURVATURE
*
         RC= OMXMSQ / (2. * D1 * OMXMT - .588) * .20 / TOC
         ENDIF
************************************************************************
* 
*  FOR X/C = 0 TO X/C = XMT, CALCULATE THE DEPENDENT VARIABLES
* 
         IF(.NOT. (X(I) .GT. XMT)) THEN
         SRX= SQRT(X(I))
         XSQ= X(I) * X(I)
         XCU= XSQ * X(I)
         SRXCU= SQRT(XCU)
         V5= 0.
* 
*  CALCULATE THICKNESS Y (Y/C)
* 
         V1= A0 * SRX
         V2= A1 * X(I)
         V3= A2 * XSQ
         V4= A3 * XCU
         Y= V1 + V2 + V3 + V4 + V5
* 
*  CALCULATE YP, THE FIRST DERIVATIVE OF Y
* 
            IF(SRX .GT. 0.) THEN
            V1= A0 * .5 * (1./SRX)
            V3= A2 * 2. * X(I)
            V4= A3 * 3. * XSQ
            YP= V1 + A1 + V3 + V4 + V5
            ELSE
            YP= 999.E20
            ENDIF
*
*  CALCULATE YPP, THE SECOND DERIVATIVE OF Y
* 
            IF(SRXCU .GT. 0.) THEN
            V1= A0 * .5 * .5 * (-1./SRXCU)
            V3= A2 * 2. * 1.
            V4= A3 * 3. * 2. * X(I)
            YPP= V1 + 0. + V3 + V4 + V5
            ELSE
            YPP= -999.E20
            ENDIF
************************************************************************
*
*  FOR X/C = XMT TO X/C = 1, CALCULATE THE DEPENDENT VARIABLES
*
         ELSE
         OMX= 1. - X(I)
         OMXSQ= OMX * OMX
         OMXCU= OMXSQ * OMX
         V5= 0.
* 
*  CALCULATE Y (Y/C)
* 
         V1= D0
         V2= D1 * OMX
         V3= D2 * OMXSQ
         V4= D3 * OMXCU
         Y= V1 + V2 + V3 + V4 + V5
* 
*  CALCULATE YP, THE FIRST DERIVATIVE OF Y
* 
         V1= 0.
         V2= D1 * (-1.)
         V3= D2 * (-2.) * OMX
         V4= D3 * (-3.) * OMXSQ
         YP= V1 + V2 + V3 + V4 + V5
*
*  CALCULATE YPP, THE SECOND DERIVATIVE OF Y
* 
         V2= 0.
         V3= D2 * (-2.) * (-1.)
         V4= D3 * (-3.) * (-2.) * OMX
         YPP= V1 + 0. + V3 + V4 + V5
         ENDIF
*
*  ADJUST FROM THE STANDARD .20 TO THE DESIRED THICKNESS TO CHORD RATIO
*
      Y= Y * TOC / .20
      YP= YP * TOC / .20
      YPP= YPP * TOC / .20
*
*
*  ROUTINE -TDM4D- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 DEC 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE TITLE   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
************************************************************************
      SUBROUTINE TITLE 
* 
*  SPECIFICATIONS
* 
      INCLUDE 'pssc.h'
* 
*  WRITE A TITLE TO THE SCREEN 
* 
      WRITE(*,'(T10,''----------------------------------------'')') 
      WRITE(*,'(T13,''The NACA Airfoil Ordinate Generator'')') 
      WRITE(*,'(/,T16,''Release '',A,T31,A)') VSNUM, VSDATE
      WRITE(*,'(T10,''----------------------------------------'')') 
      WRITE(*,'(T16,A)') VSDESC
      CALL WAITT(1.)
*  
*  ROUTINE -TITLE- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 31 DEC 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE TUTOR
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE TUTOR
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'chstg.h'
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      INCLUDE 'lists.h'
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
*
      CHARACTER TYP*3
* 
*  INITIALIZATIONS
* 
      NDX1= ICHAR('T')
      NUMOPS= ICHAR('F')
      TYP= 'LOG'
* 
*  INQUIRE ABOUT EXPERIENCE USING PROGRAM
* 
      IOP1= NQUIRY(ADVIC6, CUES1(6), LIST6, NDX1, NUMOPS, TYP) 
************************************************************************
* 
*  IF EXPERIENCED, EXECUTION OF THE TUTORIAL NOT REQUIRED
*
      IF(IOP1 .EQ. IOPE .OR. IOP1 .EQ. 1) GO TO 990
*
*  PROCESS REQUEST FOR EXECUTION OF THE TUTORIAL
*
      ENTRY SHXAMP
*
*  ASSIGN CODE TO PLACE PROGRAM IN EXAMPLE MODE
*
      MEX= ITRUE
*
*  ASSIGN NEW VALUES TO VARIABLES
*
      NDX1= 1
      NUMOPS= 4
      TYP= 'SEL'
*
*  WRITE INPUTS FOR USER TO SCRATCH FILE
*
      OPEN(9,FILE='ANS.DAT',STATUS='UNKNOWN')
      WRITE(9,'(A)') (ANS(I), I=1,10)
      REWIND 9
* 
*  CLEAR TERMINAL SCREEN
* 
      CALL CLRSC
*
*  WRITE PAGE BANNER
*
      CALL BANNER 
* 
*  WRITE A MESSAGE TO THE SCREEN 
* 
      CALL MESSGE('ENTER NO INPUTS FOR TUTORIAL, THEY ARE SUPPLIED')
* 
*  QUERY USER WITH EXAMPLE TO SHOW MENU OPTIONS AVAILABLE BY
*  MIMICKING CALL TO NQUIRY WITHOUT READING INPUT FROM USER
*
      I= 1
 200     IOP1= NQURY1(ADVIC7, CUES1(7), LIST7, NDX1, NUMOPS, TYP) 
         CALL XPLAIN(MESSG1(I*4-3), .TRUE.)
         IF(IOP1 .EQ. IOPQ) GO TO 201
         I= I + 1
         GO TO 200
 201     CONTINUE
*
*  CLOSE AND REMOVE THE SCRATCH FILE
*
      CLOSE(9)
      OPEN(9,FILE='ANS.DAT',STATUS='OLD')
      CLOSE(9,STATUS='DELETE')
* 
*  CLEAR TERMINAL SCREEN
* 
      CALL CLRSC
*
*  WRITE PAGE BANNER
*
      CALL BANNER 
* 
*  WRITE A MESSAGE TO THE SCREEN 
* 
      CALL MESSGE('REVERT TO SUPPLING INPUTS, TUTORIAL HAS COMPLETED')
*
*  ASSIGN CODE TO REMOVE PROGRAM FROM EXAMPLE MODE
*
      MEX= IFALSE
* 
*  ROUTINE -TUTOR- COMPLETE 
* 
 990  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 28 AUG 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE WAITT    
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE WAITT(VAL)
* 
*  SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
      CHARACTER ANS*1, RDNTRY*1
* 
*  INITIALIZATIONS
* 
*
*  TEST FOR PROGRAM IN EXAMPLE MODE
*
         IF(VAL .GT. 0.0) THEN
            IF(MEX .NE. ITRUE) THEN
            ANS= RDNTRY('<CR> TO CONTINUE', 0, 0, 'ANS')
	    ELSE
	    PAUSE
	    ENDIF
	 ENDIF
* 
*  ROUTINE -WAITT- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 21 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE WRFORM   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE WRFORM
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
*
*  INITIALIZATIONS
*
      KREC= KOUNTX + 1
*
*  PRINT INITIAL TABLE DATA
*
      WRITE(IUR,'('' AIRFOLS ORDINATE INFORMATION REPORT'')')
      WRITE(IUR,'('' for '',A,'' airfoil'',/)') TITLE(:NDCH(TITLE))
      WRITE(IUR,'('' PROFILE:  '',A12,''     CAMBER:  '',A12,//)')
     +      DESIGP,DESIGC
*
*  PRINT INITIAL PROFILE DATA
*
      WRITE(IUR,'('' PROFILE PARAMETERS: '')')
      WRITE(IUR,'(T3,F9.6,T15,''= THICKNESS / CHORD  (TOC)'')') TOC
      WRITE(IUR,'(T3,F9.6,T15,''= BASIC X INTERVAL  (DX)'')') DX
      WRITE(IUR,'(T3,F9.6,T15,''= MODEL CHORD  (CHD)'',/)') CHD
*
*  PRINT TO THE FORM THE PROFILE SPECIFIC DATA
*
      CALL FRMPRF
*
*  IF CAMBERED, PRINT TO THE FORM THE CAMBER SPECIFIC DATA
* 
         IF((MLC .GT. 0)) THEN
         WRITE(IUR,'(/)') 
         WRITE(IUR,'('' CAMBER PARAMETERS: '')')
         CALL FRMCAM
*
*  PRINT CAMBERED AIRFOIL TABLE BANNER
*
         WRITE(IUR,'(///)') 
         WRITE(IUR,1090)
 1090    FORMAT(T2,'UNCAMBERED',T33,'UPPER SURFACE VALUES',T94,
     +          'LOWER SURFACE VALUES')
         WRITE(IUR,1100)
 1100    FORMAT(T6,'X/C',T20,'XU/C',T31,'YU/C',T43,'XU',T54,'YU',T62,
     +          'DYU/DXU',T81,'XL/C',T92,'YL/C',T104,'XL',T115,'YL',
     +          T123,'DYL/DXL')
*
*  PRINT UNCAMBERED AIRFOIL TABLE BANNER
*
         ELSE
         WRITE(IUR,'(///)') 
         WRITE(IUR,1110)
 1110    FORMAT(T6,'X/C',T17,'Y/C',T31,'X',T42,'Y',T56,'DY/DX',T70,
     +          'D2Y/DX2')
         ENDIF
      WRITE(IUR,'('' '')') 
*
*  ROUTINE -WRFORM- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 22 JAN 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE WRNTRY   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE WRNTRY(I)
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
      INCLUDE 'numfil.h'
*
*  INTIALIZATIONS
*
      KREC= KREC - 1
*
*  PRINT UNCAMBERED AIRFOIL TABLE ENTRIES
*
         IF(.NOT.(MLC .GT. 0)) THEN
         WRITE(IUD,'(2F13.6)') XC, YC
         WRITE(IUA,REC=KREC) XC, -(YC)
         WRITE(IUR,'(T2,2(F9.6,2X),T26,2(F9.6,2X),T50,2(2X,F13.6))')
     +         X(I), Y, XC, YC, YP, YPP
*
*  PRINT CAMBERED AIRFOIL TABLE ENTRIES
*
         ELSE
         WRITE(IUD,'(2F13.6)') XCU, YCU
         WRITE(IUA,REC=KREC) XCL, YCL
         WRITE(IUR,'(F10.6, 4X, 5F11.6, 6X, 5F11.6)') 
     +         X(I), XU, YU, XCU, YCU, YPU, XL, YL, XCL, YCL, YPL 
         ENDIF
*
*  ROUTINE -WRNTRY- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 24 DEC 86, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE XPLAIN  
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE XPLAIN(ADVIC,NWPAG)
* 
*  SPECIFICATIONS 
* 
      CHARACTER*(*) ADVIC(*), FORM*5
      LOGICAL NWPAG
*
*  INTIALIZATIONS
*
      FORM= '(Ixx)'
      NCHR= NDCH(ADVIC(1)) 
      WRITE(FORM(3:4),'(I2.2)') NCHR
*
*  DERIVE NUMBER OF TEXT LINES IN EXPLANATION
*
      READ(ADVIC(1),FORM) NLINE
      IF(NLINE .EQ. 0) GO TO 999
      NLINE= NLINE + 1
*
*  TEST FOR NEW PAGE REQUEST
*
         IF(NWPAG) THEN
* 
*  CLEAR TERMINAL SCREEN
* 
         CALL CLRSC
*
*  WRITE PAGE BANNER
*
         CALL BANNER
         WRITE(*,'(//)')
         ELSE
         WRITE(*,'()')
         ENDIF
* 
*  WRITE THE EXPLANATION TO THE SCREEN 
* 
         DO 100 I= 2,NLINE
 100     WRITE(*,'(T11,A)') ADVIC(I)(:NDCH(ADVIC(I)))
*
*  DELAY FOR INFORMATION TO BE READ
*
      CALL WAITT(1.)
* 
*  ROUTINE -XPLAIN- COMPLETE 
* 
 999  RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 07 JAN 92, 804-865-1725 CCCCCCCCCC
C
C
C>                           SUBROUTINE XS
C
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          DX VALUES OF 1%, 5%, AND 10% WILL PRODUCE RATIONAL VALUES.
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          DWS-01MAR96-ADD CAPABILITY TO PRODUCE RATIONAL X-ARRAY VALUES.
************************************************************************
*
*  CALCULATES AND STORES THE X'S FOR THE LOCATIONS ON THE CORD (X/C).
*
************************************************************************
      SUBROUTINE XS
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'afdesc.h'
*
      INTEGER*4 I
      LOGICAL EQR, LEDGE, RATVAL
      REAL*4 DEVIS, FRAC, XMAX
* 
*  INITIALIZATIONS
* 
      KOUNTX= 0
      LEDGE= .TRUE.
      XMAX= 1.0
*
*  IF EQUAL TO ZERO, ASSIGN MAXIMUM THICKNESS LOCATION
*
      IF(EQR(XMT,0.0)) XMT= .5
*
      X(1)= 0.0
      I= 1
*
*  IF DX EQUAL TO 1%, 5%, OR 10% RATIONAL VALUES REQUESTED
*
         IF((DX .EQ. .01) .OR. 
     .      (DX .EQ. .05) .OR. 
     .      (DX .EQ. .10)) THEN
         RATVAL= .TRUE.
         DEVIS= 1./4.
*
         ELSE
         RATVAL= .FALSE.
         DEVIS= 1.0
         X(2)= .00025
         I= 2
         ENDIF
* 
*  DERIVE THE FRACTIONAL INDEX TO USE
* 
100      CONTINUE
            IF(RATVAL) THEN
* 
*  IF DX, 1%, 5%, OR 10%, PRODUCE RATIONAL VALUES FOR X-ARRAY
* 
               IF(DX-X(I) .GT. DX/40.) THEN
               FRAC= 0.1
               ELSE IF(EQR(X(I),DX) .AND. (.1-X(I) .GT. DX/4.)) THEN
               FRAC= 1.0
               ELSE IF (EQR(X(I),.1)) THEN
               FRAC= 4.0
               ENDIF
            ELSE
*
*  FOR OTHER VALUES OF DX, PRODUCE EQUAL INCREMENTS
*
               IF((X(I) .LT. .01225).OR.(EQR(X(I),.01225))) THEN
               FRAC= .025
               ELSE IF((X(I) .LT. .0975).OR.(EQR(X(I),.0975))) THEN
               FRAC= .25
               ELSE
               FRAC= 1.0
               ENDIF
            ENDIF
*
*  CALCULATE THE NEXT X AND INCREMENT COUNTER
*
         X(I+1)= X(I) + (DX * FRAC * DEVIS)
            IF(I .LE. 300) THEN
            I= I + 1
            ELSE
            CALL MESSGE('F-ERROR/ ARRAY LIMIT EXCEEDED /SUB XS')
            ENDIF
*
*  ENSURE A "X" VALUE EQUAL TO XMT
*
            IF((LEDGE) .AND. ((X(I) .GT. XMT).OR.(EQR(X(I),XMT)))) THEN
            LEDGE= .FALSE.
            X(I)= XMT
            ENDIF
*
         IF(.NOT. EQR(X(I),XMAX)) GO TO 100
      KOUNTX= I
*
*  ROUTINE -XS- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 21 AUG 87, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           SUBROUTINE ZINITS   
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  description
*
************************************************************************
      SUBROUTINE ZINITS
* 
*  SPECIFICATIONS 
* 
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
* 
*  INITIALIZATIONS
* 
      IDT= 0
      IOS= 0
      MEX= IFALSE
      MPR= IFALSE
* 
      IOP= 0
* 
*  ROUTINE -ZINITS- COMPLETE 
* 
      RETURN
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 12 MAR 92, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           BDTA6S 
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  BLOCK DATA PROGRAM SPECIFICATIONS FOR 6 AND 6A SERIES PROFILES.
*  THE SECOND INDEX TO THE ARRAYS EPS AND PSI (J=1,8) HAVE THE ASSOCIATIONS;
*
*  J=1             63 SERIES           IAD=1
*  J=2             64 SERIES           IAD=2
*  J=3             65 SERIES           IAD=3
*  J=4             66 SERIES           IAD=4
*  J=5             67 SERIES           IAD=5
*
*  J=6             63A SERIES          IAD=1 +5
*  J=7             64A SERIES          IAD=2 +5
*  J=8             65A SERIES          IAD=3 +5
*
*  THE SECOND INDEX J IS THE VALUE OF PARAMETER IAD IN THE ROUTINE CAL6SF 
*  WHICH IS ASSIGNED FROM USER INPUT IN THE ROUTINE ASINP TO (IAD=1,5) TO 
*  REFERENCE 6 SERIES, OR (5 + IAD=1,3) TO REFERENCE 6A SERIES PROFILES.
*
************************************************************************
      BLOCK DATA BDTA6S 
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'af6s.h'
* 
*  INITIALIZATIONS
* 
************************************************************************
      DATA (PHI(I),I=001,004)/  0.00000,  0.01571,  0.03142,  0.04712  /
      DATA (PHI(I),I=005,008)/  0.06283,  0.07854,  0.09425,  0.10996  /
      DATA (PHI(I),I=009,012)/  0.12566,  0.14137,  0.15708,  0.17279  /
      DATA (PHI(I),I=013,016)/  0.18850,  0.20420,  0.21991,  0.23562  /
      DATA (PHI(I),I=017,020)/  0.25133,  0.26704,  0.28274,  0.29845  /
      DATA (PHI(I),I=021,024)/  0.31416,  0.32987,  0.34558,  0.36128  /
      DATA (PHI(I),I=025,028)/  0.37699,  0.39270,  0.40841,  0.42412  /
      DATA (PHI(I),I=029,032)/  0.43982,  0.45553,  0.47124,  0.48695  /
      DATA (PHI(I),I=033,036)/  0.50265,  0.51836,  0.53407,  0.54978  /
      DATA (PHI(I),I=037,040)/  0.56549,  0.58119,  0.59690,  0.61261  /
      DATA (PHI(I),I=041,044)/  0.62832,  0.64403,  0.65973,  0.67544  /
      DATA (PHI(I),I=045,048)/  0.69115,  0.70686,  0.72257,  0.73827  /
      DATA (PHI(I),I=049,052)/  0.75398,  0.76969,  0.78540,  0.80111  /
      DATA (PHI(I),I=053,056)/  0.81681,  0.83252,  0.84823,  0.86394  /
      DATA (PHI(I),I=057,060)/  0.87965,  0.89535,  0.91106,  0.92677  /
      DATA (PHI(I),I=061,064)/  0.94248,  0.95819,  0.97389,  0.98960  /
      DATA (PHI(I),I=065,068)/  1.00531,  1.02102,  1.03673,  1.05243  /
      DATA (PHI(I),I=069,072)/  1.06814,  1.08385,  1.09956,  1.11527  /
      DATA (PHI(I),I=073,076)/  1.13097,  1.14668,  1.16239,  1.17810  /
      DATA (PHI(I),I=077,080)/  1.19381,  1.20951,  1.22522,  1.24093  /
      DATA (PHI(I),I=081,084)/  1.25664,  1.27235,  1.28805,  1.30376  /
      DATA (PHI(I),I=085,088)/  1.31947,  1.33518,  1.35088,  1.36659  /
      DATA (PHI(I),I=089,092)/  1.38230,  1.39801,  1.41372,  1.42942  /
      DATA (PHI(I),I=093,096)/  1.44513,  1.46084,  1.47655,  1.49226  /
      DATA (PHI(I),I=097,100)/  1.50796,  1.52367,  1.53938,  1.55509  /
      DATA (PHI(I),I=101,104)/  1.57080,  1.58650,  1.60221,  1.61792  /
      DATA (PHI(I),I=105,108)/  1.63363,  1.64934,  1.66504,  1.68075  /
      DATA (PHI(I),I=109,112)/  1.69646,  1.71217,  1.72788,  1.74358  /
      DATA (PHI(I),I=113,116)/  1.75929,  1.77500,  1.79071,  1.80642  /
      DATA (PHI(I),I=117,120)/  1.82212,  1.83783,  1.85354,  1.86925  /
      DATA (PHI(I),I=121,124)/  1.88496,  1.90066,  1.91637,  1.93208  /
      DATA (PHI(I),I=125,128)/  1.94779,  1.96350,  1.97920,  1.99491  /
      DATA (PHI(I),I=129,132)/  2.01062,  2.02633,  2.04204,  2.05774  /
      DATA (PHI(I),I=133,136)/  2.07345,  2.08916,  2.10487,  2.12057  /
      DATA (PHI(I),I=137,140)/  2.13628,  2.15199,  2.16770,  2.18341  /
      DATA (PHI(I),I=141,144)/  2.19912,  2.21482,  2.23053,  2.24624  /
      DATA (PHI(I),I=145,148)/  2.26195,  2.27765,  2.29336,  2.30907  /
      DATA (PHI(I),I=149,152)/  2.32478,  2.34049,  2.35619,  2.37190  /
      DATA (PHI(I),I=153,156)/  2.38761,  2.40332,  2.41903,  2.43473  /
      DATA (PHI(I),I=157,160)/  2.45044,  2.46615,  2.48186,  2.49757  /
      DATA (PHI(I),I=161,164)/  2.51327,  2.52898,  2.54469,  2.56040  /
      DATA (PHI(I),I=165,168)/  2.57611,  2.59181,  2.60752,  2.62323  /
      DATA (PHI(I),I=169,172)/  2.63894,  2.65465,  2.67035,  2.68606  /
      DATA (PHI(I),I=173,176)/  2.70177,  2.71748,  2.73319,  2.74889  /
      DATA (PHI(I),I=177,180)/  2.76460,  2.78031,  2.79602,  2.81173  /
      DATA (PHI(I),I=181,184)/  2.82743,  2.84314,  2.85885,  2.87456  /
      DATA (PHI(I),I=185,188)/  2.89027,  2.90597,  2.92168,  2.93739  /
      DATA (PHI(I),I=189,192)/  2.95310,  2.96881,  2.98451,  3.00022  /
      DATA (PHI(I),I=193,196)/  3.01593,  3.03164,  3.04734,  3.06305  /
      DATA (PHI(I),I=197,200)/  3.07876,  3.09447,  3.11018,  3.12588  /
      DATA  PHI(201)         /  3.14159  /
************************************************************************
************************************************************************
      DATA (EPS(I,1),I=001,004)/  0.00000,  0.00164,  0.00327,  0.00487/
      DATA (EPS(I,1),I=005,008)/  0.00641,  0.00790,  0.00928,  0.01057/
      DATA (EPS(I,1),I=009,012)/  0.01174,  0.01278,  0.01367,  0.01439/
      DATA (EPS(I,1),I=013,016)/  0.01497,  0.01542,  0.01576,  0.01601/
      DATA (EPS(I,1),I=017,020)/  0.01619,  0.01632,  0.01642,  0.01651/
      DATA (EPS(I,1),I=021,024)/  0.01661,  0.01673,  0.01688,  0.01705/
      DATA (EPS(I,1),I=025,028)/  0.01725,  0.01747,  0.01771,  0.01797/
      DATA (EPS(I,1),I=029,032)/  0.01824,  0.01853,  0.01884,  0.01916/
      DATA (EPS(I,1),I=033,036)/  0.01949,  0.01984,  0.02020,  0.02058/
      DATA (EPS(I,1),I=037,040)/  0.02097,  0.02137,  0.02179,  0.02223/
      DATA (EPS(I,1),I=041,044)/  0.02268,  0.02315,  0.02363,  0.02413/
      DATA (EPS(I,1),I=045,048)/  0.02464,  0.02517,  0.02571,  0.02626/
      DATA (EPS(I,1),I=049,052)/  0.02683,  0.02741,  0.02801,  0.02862/
      DATA (EPS(I,1),I=053,056)/  0.02924,  0.02988,  0.03052,  0.03118/
      DATA (EPS(I,1),I=057,060)/  0.03185,  0.03253,  0.03323,  0.03393/
      DATA (EPS(I,1),I=061,064)/  0.03465,  0.03538,  0.03611,  0.03686/
      DATA (EPS(I,1),I=065,068)/  0.03762,  0.03839,  0.03917,  0.03995/
      DATA (EPS(I,1),I=069,072)/  0.04075,  0.04156,  0.04237,  0.04319/
      DATA (EPS(I,1),I=073,076)/  0.04402,  0.04486,  0.04571,  0.04657/
      DATA (EPS(I,1),I=077,080)/  0.04743,  0.04831,  0.04919,  0.05008/
      DATA (EPS(I,1),I=081,084)/  0.05098,  0.05189,  0.05280,  0.05372/
      DATA (EPS(I,1),I=085,088)/  0.05464,  0.05556,  0.05648,  0.05740/
      DATA (EPS(I,1),I=089,092)/  0.05831,  0.05921,  0.06011,  0.06099/
      DATA (EPS(I,1),I=093,096)/  0.06187,  0.06273,  0.06357,  0.06440/
      DATA (EPS(I,1),I=097,100)/  0.06522,  0.06602,  0.06681,  0.06757/
      DATA (EPS(I,1),I=101,104)/  0.06832,  0.06905,  0.06976,  0.07044/
      DATA (EPS(I,1),I=105,108)/  0.07111,  0.07176,  0.07238,  0.07298/
      DATA (EPS(I,1),I=109,112)/  0.07356,  0.07411,  0.07464,  0.07514/
      DATA (EPS(I,1),I=113,116)/  0.07562,  0.07607,  0.07650,  0.07690/
      DATA (EPS(I,1),I=117,120)/  0.07727,  0.07761,  0.07793,  0.07822/
      DATA (EPS(I,1),I=121,124)/  0.07848,  0.07871,  0.07891,  0.07908/
      DATA (EPS(I,1),I=125,128)/  0.07922,  0.07933,  0.07941,  0.07945/
      DATA (EPS(I,1),I=129,132)/  0.07946,  0.07944,  0.07938,  0.07929/
      DATA (EPS(I,1),I=133,136)/  0.07916,  0.07900,  0.07880,  0.07856/
      DATA (EPS(I,1),I=137,140)/  0.07829,  0.07799,  0.07764,  0.07726/
      DATA (EPS(I,1),I=141,144)/  0.07685,  0.07640,  0.07591,  0.07539/
      DATA (EPS(I,1),I=145,148)/  0.07483,  0.07423,  0.07359,  0.07293/
      DATA (EPS(I,1),I=149,152)/  0.07222,  0.07148,  0.07070,  0.06989/
      DATA (EPS(I,1),I=153,156)/  0.06904,  0.06815,  0.06723,  0.06628/
      DATA (EPS(I,1),I=157,160)/  0.06529,  0.06427,  0.06322,  0.06214/
      DATA (EPS(I,1),I=161,164)/  0.06103,  0.05989,  0.05871,  0.05751/
      DATA (EPS(I,1),I=165,168)/  0.05628,  0.05502,  0.05374,  0.05243/
      DATA (EPS(I,1),I=169,172)/  0.05109,  0.04973,  0.04834,  0.04693/
      DATA (EPS(I,1),I=173,176)/  0.04549,  0.04404,  0.04256,  0.04106/
      DATA (EPS(I,1),I=177,180)/  0.03955,  0.03802,  0.03647,  0.03491/
      DATA (EPS(I,1),I=181,184)/  0.03333,  0.03174,  0.03014,  0.02853/
      DATA (EPS(I,1),I=185,188)/  0.02690,  0.02527,  0.02363,  0.02198/
      DATA (EPS(I,1),I=189,192)/  0.02032,  0.01865,  0.01698,  0.01530/
      DATA (EPS(I,1),I=193,196)/  0.01361,  0.01192,  0.01023,  0.00853/
      DATA (EPS(I,1),I=197,200)/  0.00683,  0.00512,  0.00342,  0.00171/
      DATA  EPS(201,1)         /  0.00000  /
************************************************************************
      DATA (EPS(I,2),I=001,004)/  0.00000,  0.00233,  0.00465,  0.00693/
      DATA (EPS(I,2),I=005,008)/  0.00915,  0.01130,  0.01337,  0.01532/
      DATA (EPS(I,2),I=009,012)/  0.01715,  0.01884,  0.02035,  0.02169/
      DATA (EPS(I,2),I=013,016)/  0.02288,  0.02391,  0.02481,  0.02557/
      DATA (EPS(I,2),I=017,020)/  0.02624,  0.02682,  0.02731,  0.02774/
      DATA (EPS(I,2),I=021,024)/  0.02812,  0.02846,  0.02877,  0.02905/
      DATA (EPS(I,2),I=025,028)/  0.02931,  0.02957,  0.02982,  0.03007/
      DATA (EPS(I,2),I=029,032)/  0.03033,  0.03060,  0.03090,  0.03122/
      DATA (EPS(I,2),I=033,036)/  0.03158,  0.03196,  0.03236,  0.03280/
      DATA (EPS(I,2),I=037,040)/  0.03326,  0.03375,  0.03427,  0.03481/
      DATA (EPS(I,2),I=041,044)/  0.03538,  0.03598,  0.03660,  0.03725/
      DATA (EPS(I,2),I=045,048)/  0.03792,  0.03862,  0.03935,  0.04010/
      DATA (EPS(I,2),I=049,052)/  0.04087,  0.04167,  0.04250,  0.04335/
      DATA (EPS(I,2),I=053,056)/  0.04423,  0.04512,  0.04605,  0.04699/
      DATA (EPS(I,2),I=057,060)/  0.04796,  0.04896,  0.04998,  0.05102/
      DATA (EPS(I,2),I=061,064)/  0.05208,  0.05317,  0.05428,  0.05541/
      DATA (EPS(I,2),I=065,068)/  0.05657,  0.05774,  0.05894,  0.06016/
      DATA (EPS(I,2),I=069,072)/  0.06140,  0.06267,  0.06395,  0.06526/
      DATA (EPS(I,2),I=073,076)/  0.06658,  0.06793,  0.06931,  0.07070/
      DATA (EPS(I,2),I=077,080)/  0.07213,  0.07357,  0.07505,  0.07655/
      DATA (EPS(I,2),I=081,084)/  0.07808,  0.07964,  0.08123,  0.08284/
      DATA (EPS(I,2),I=085,088)/  0.08447,  0.08613,  0.08780,  0.08949/
      DATA (EPS(I,2),I=089,092)/  0.09119,  0.09290,  0.09462,  0.09635/
      DATA (EPS(I,2),I=093,096)/  0.09808,  0.09980,  0.10151,  0.10321/
      DATA (EPS(I,2),I=097,100)/  0.10488,  0.10653,  0.10815,  0.10972/
      DATA (EPS(I,2),I=101,104)/  0.11125,  0.11273,  0.11415,  0.11553/
      DATA (EPS(I,2),I=105,108)/  0.11686,  0.11814,  0.11938,  0.12057/
      DATA (EPS(I,2),I=109,112)/  0.12171,  0.12281,  0.12386,  0.12487/
      DATA (EPS(I,2),I=113,116)/  0.12583,  0.12675,  0.12762,  0.12844/
      DATA (EPS(I,2),I=117,120)/  0.12922,  0.12994,  0.13062,  0.13125/
      DATA (EPS(I,2),I=121,124)/  0.13182,  0.13234,  0.13281,  0.13322/
      DATA (EPS(I,2),I=125,128)/  0.13358,  0.13389,  0.13414,  0.13434/
      DATA (EPS(I,2),I=129,132)/  0.13448,  0.13456,  0.13459,  0.13456/
      DATA (EPS(I,2),I=133,136)/  0.13447,  0.13433,  0.13413,  0.13387/
      DATA (EPS(I,2),I=137,140)/  0.13354,  0.13316,  0.13272,  0.13222/
      DATA (EPS(I,2),I=141,144)/  0.13166,  0.13104,  0.13035,  0.12960/
      DATA (EPS(I,2),I=145,148)/  0.12879,  0.12792,  0.12698,  0.12598/
      DATA (EPS(I,2),I=149,152)/  0.12492,  0.12380,  0.12261,  0.12136/
      DATA (EPS(I,2),I=153,156)/  0.12004,  0.11866,  0.11723,  0.11573/
      DATA (EPS(I,2),I=157,160)/  0.11417,  0.11255,  0.11087,  0.10914/
      DATA (EPS(I,2),I=161,164)/  0.10735,  0.10550,  0.10361,  0.10165/
      DATA (EPS(I,2),I=165,168)/  0.09964,  0.09758,  0.09546,  0.09329/
      DATA (EPS(I,2),I=169,172)/  0.09106,  0.08878,  0.08645,  0.08406/
      DATA (EPS(I,2),I=173,176)/  0.08163,  0.07914,  0.07661,  0.07403/
      DATA (EPS(I,2),I=177,180)/  0.07140,  0.06874,  0.06604,  0.06329/
      DATA (EPS(I,2),I=181,184)/  0.06052,  0.05770,  0.05487,  0.05199/
      DATA (EPS(I,2),I=185,188)/  0.04908,  0.04615,  0.04319,  0.04021/
      DATA (EPS(I,2),I=189,192)/  0.03721,  0.03417,  0.03113,  0.02807/
      DATA (EPS(I,2),I=193,196)/  0.02499,  0.02189,  0.01879,  0.01567/
      DATA (EPS(I,2),I=197,200)/  0.01255,  0.00942,  0.00628,  0.00314/
      DATA  EPS(201,2)         /  0.00000  /
************************************************************************
      DATA (EPS(I,3),I=001,004)/  0.00000,  0.00165,  0.00330,  0.00493/
      DATA (EPS(I,3),I=005,008)/  0.00653,  0.00810,  0.00963,  0.01110/
      DATA (EPS(I,3),I=009,012)/  0.01253,  0.01387,  0.01515,  0.01625/
      DATA (EPS(I,3),I=013,016)/  0.01702,  0.01746,  0.01771,  0.01795/
      DATA (EPS(I,3),I=017,020)/  0.01824,  0.01858,  0.01893,  0.01922/
      DATA (EPS(I,3),I=021,024)/  0.01943,  0.01951,  0.01945,  0.01926/
      DATA (EPS(I,3),I=025,028)/  0.01899,  0.01865,  0.01830,  0.01794/
      DATA (EPS(I,3),I=029,032)/  0.01760,  0.01733,  0.01715,  0.01704/
      DATA (EPS(I,3),I=033,036)/  0.01702,  0.01706,  0.01715,  0.01727/
      DATA (EPS(I,3),I=037,040)/  0.01742,  0.01759,  0.01777,  0.01798/
      DATA (EPS(I,3),I=041,044)/  0.01821,  0.01846,  0.01876,  0.01908/
      DATA (EPS(I,3),I=045,048)/  0.01944,  0.01983,  0.02024,  0.02068/
      DATA (EPS(I,3),I=049,052)/  0.02114,  0.02161,  0.02211,  0.02261/
      DATA (EPS(I,3),I=053,056)/  0.02313,  0.02365,  0.02419,  0.02474/
      DATA (EPS(I,3),I=057,060)/  0.02530,  0.02587,  0.02647,  0.02708/
      DATA (EPS(I,3),I=061,064)/  0.02772,  0.02837,  0.02904,  0.02974/
      DATA (EPS(I,3),I=065,068)/  0.03046,  0.03119,  0.03195,  0.03271/
      DATA (EPS(I,3),I=069,072)/  0.03350,  0.03429,  0.03510,  0.03593/
      DATA (EPS(I,3),I=073,076)/  0.03677,  0.03763,  0.03849,  0.03938/
      DATA (EPS(I,3),I=077,080)/  0.04028,  0.04119,  0.04212,  0.04307/
      DATA (EPS(I,3),I=081,084)/  0.04404,  0.04502,  0.04602,  0.04704/
      DATA (EPS(I,3),I=085,088)/  0.04808,  0.04914,  0.05021,  0.05130/
      DATA (EPS(I,3),I=089,092)/  0.05241,  0.05353,  0.05467,  0.05582/
      DATA (EPS(I,3),I=093,096)/  0.05699,  0.05817,  0.05935,  0.06055/
      DATA (EPS(I,3),I=097,100)/  0.06174,  0.06294,  0.06414,  0.06534/
      DATA (EPS(I,3),I=101,104)/  0.06653,  0.06772,  0.06890,  0.07006/
      DATA (EPS(I,3),I=105,108)/  0.07121,  0.07234,  0.07346,  0.07456/
      DATA (EPS(I,3),I=109,112)/  0.07564,  0.07668,  0.07771,  0.07872/
      DATA (EPS(I,3),I=113,116)/  0.07970,  0.08064,  0.08155,  0.08244/
      DATA (EPS(I,3),I=117,120)/  0.08327,  0.08406,  0.08480,  0.08550/
      DATA (EPS(I,3),I=121,124)/  0.08614,  0.08673,  0.08728,  0.08778/
      DATA (EPS(I,3),I=125,128)/  0.08825,  0.08866,  0.08905,  0.08939/
      DATA (EPS(I,3),I=129,132)/  0.08968,  0.08995,  0.09017,  0.09034/
      DATA (EPS(I,3),I=133,136)/  0.09048,  0.09057,  0.09062,  0.09061/
      DATA (EPS(I,3),I=137,140)/  0.09057,  0.09046,  0.09031,  0.09009/
      DATA (EPS(I,3),I=141,144)/  0.08982,  0.08950,  0.08911,  0.08868/
      DATA (EPS(I,3),I=145,148)/  0.08819,  0.08765,  0.08707,  0.08643/
      DATA (EPS(I,3),I=149,152)/  0.08576,  0.08504,  0.08427,  0.08346/
      DATA (EPS(I,3),I=153,156)/  0.08260,  0.08170,  0.08075,  0.07976/
      DATA (EPS(I,3),I=157,160)/  0.07871,  0.07759,  0.07640,  0.07510/
      DATA (EPS(I,3),I=161,164)/  0.07368,  0.07216,  0.07047,  0.06864/
      DATA (EPS(I,3),I=165,168)/  0.06664,  0.06448,  0.06220,  0.05982/
      DATA (EPS(I,3),I=169,172)/  0.05735,  0.05483,  0.05228,  0.04972/
      DATA (EPS(I,3),I=173,176)/  0.04718,  0.04467,  0.04225,  0.03991/
      DATA (EPS(I,3),I=177,180)/  0.03766,  0.03548,  0.03338,  0.03135/
      DATA (EPS(I,3),I=181,184)/  0.02939,  0.02752,  0.02569,  0.02394/
      DATA (EPS(I,3),I=185,188)/  0.02224,  0.02059,  0.01899,  0.01744/
      DATA (EPS(I,3),I=189,192)/  0.01592,  0.01446,  0.01302,  0.01163/
      DATA (EPS(I,3),I=193,196)/  0.01026,  0.00892,  0.00761,  0.00630/
      DATA (EPS(I,3),I=197,200)/  0.00502,  0.00376,  0.00250,  0.00124/
      DATA  EPS(201,3)         /  0.00000  /
************************************************************************
      DATA (EPS(I,4),I=001,004)/  0.00000,  0.00145,  0.00290,  0.00433/
      DATA (EPS(I,4),I=005,008)/  0.00574,  0.00712,  0.00847,  0.00978/
      DATA (EPS(I,4),I=009,012)/  0.01105,  0.01225,  0.01340,  0.01447/
      DATA (EPS(I,4),I=013,016)/  0.01547,  0.01638,  0.01719,  0.01789/
      DATA (EPS(I,4),I=017,020)/  0.01847,  0.01893,  0.01924,  0.01940/
      DATA (EPS(I,4),I=021,024)/  0.01940,  0.01924,  0.01893,  0.01850/
      DATA (EPS(I,4),I=025,028)/  0.01799,  0.01741,  0.01679,  0.01616/
      DATA (EPS(I,4),I=029,032)/  0.01556,  0.01499,  0.01450,  0.01410/
      DATA (EPS(I,4),I=033,036)/  0.01379,  0.01356,  0.01340,  0.01331/
      DATA (EPS(I,4),I=037,040)/  0.01327,  0.01328,  0.01333,  0.01340/
      DATA (EPS(I,4),I=041,044)/  0.01350,  0.01361,  0.01373,  0.01387/
      DATA (EPS(I,4),I=045,048)/  0.01402,  0.01419,  0.01438,  0.01458/
      DATA (EPS(I,4),I=049,052)/  0.01480,  0.01504,  0.01530,  0.01558/
      DATA (EPS(I,4),I=053,056)/  0.01588,  0.01620,  0.01654,  0.01689/
      DATA (EPS(I,4),I=057,060)/  0.01726,  0.01765,  0.01805,  0.01847/
      DATA (EPS(I,4),I=061,064)/  0.01890,  0.01934,  0.01980,  0.02026/
      DATA (EPS(I,4),I=065,068)/  0.02074,  0.02124,  0.02174,  0.02226/
      DATA (EPS(I,4),I=069,072)/  0.02279,  0.02334,  0.02390,  0.02447/
      DATA (EPS(I,4),I=073,076)/  0.02506,  0.02566,  0.02627,  0.02690/
      DATA (EPS(I,4),I=077,080)/  0.02754,  0.02819,  0.02885,  0.02952/
      DATA (EPS(I,4),I=081,084)/  0.03020,  0.03089,  0.03160,  0.03231/
      DATA (EPS(I,4),I=085,088)/  0.03304,  0.03378,  0.03453,  0.03530/
      DATA (EPS(I,4),I=089,092)/  0.03608,  0.03688,  0.03770,  0.03853/
      DATA (EPS(I,4),I=093,096)/  0.03938,  0.04025,  0.04113,  0.04202/
      DATA (EPS(I,4),I=097,100)/  0.04293,  0.04386,  0.04479,  0.04574/
      DATA (EPS(I,4),I=101,104)/  0.04670,  0.04767,  0.04866,  0.04966/
      DATA (EPS(I,4),I=105,108)/  0.05067,  0.05171,  0.05277,  0.05386/
      DATA (EPS(I,4),I=109,112)/  0.05498,  0.05612,  0.05730,  0.05851/
      DATA (EPS(I,4),I=113,116)/  0.05976,  0.06103,  0.06231,  0.06362/
      DATA (EPS(I,4),I=117,120)/  0.06493,  0.06625,  0.06758,  0.06889/
      DATA (EPS(I,4),I=121,124)/  0.07020,  0.07149,  0.07277,  0.07402/
      DATA (EPS(I,4),I=125,128)/  0.07524,  0.07644,  0.07760,  0.07872/
      DATA (EPS(I,4),I=129,132)/  0.07979,  0.08082,  0.08180,  0.08272/
      DATA (EPS(I,4),I=133,136)/  0.08359,  0.08440,  0.08515,  0.08585/
      DATA (EPS(I,4),I=137,140)/  0.08649,  0.08708,  0.08761,  0.08808/
      DATA (EPS(I,4),I=141,144)/  0.08850,  0.08886,  0.08916,  0.08941/
      DATA (EPS(I,4),I=145,148)/  0.08959,  0.08972,  0.08978,  0.08978/
      DATA (EPS(I,4),I=149,152)/  0.08972,  0.08959,  0.08940,  0.08914/
      DATA (EPS(I,4),I=153,156)/  0.08882,  0.08843,  0.08797,  0.08745/
      DATA (EPS(I,4),I=157,160)/  0.08687,  0.08622,  0.08551,  0.08474/
      DATA (EPS(I,4),I=161,164)/  0.08390,  0.08300,  0.08203,  0.08101/
      DATA (EPS(I,4),I=165,168)/  0.07991,  0.07876,  0.07752,  0.07622/
      DATA (EPS(I,4),I=169,172)/  0.07485,  0.07341,  0.07190,  0.07031/
      DATA (EPS(I,4),I=173,176)/  0.06865,  0.06692,  0.06511,  0.06324/
      DATA (EPS(I,4),I=177,180)/  0.06130,  0.05929,  0.05723,  0.05509/
      DATA (EPS(I,4),I=181,184)/  0.05290,  0.05064,  0.04834,  0.04597/
      DATA (EPS(I,4),I=185,188)/  0.04355,  0.04109,  0.03857,  0.03602/
      DATA (EPS(I,4),I=189,192)/  0.03342,  0.03077,  0.02810,  0.02539/
      DATA (EPS(I,4),I=193,196)/  0.02264,  0.01988,  0.01708,  0.01427/
      DATA (EPS(I,4),I=197,200)/  0.01144,  0.00858,  0.00573,  0.00287/
      DATA  EPS(201,4)         /  0.00000  /
************************************************************************
      DATA (EPS(I,5),I=001,004)/  0.00000,  0.00169,  0.00338,  0.00506/
      DATA (EPS(I,5),I=005,008)/  0.00672,  0.00835,  0.00995,  0.01152/
      DATA (EPS(I,5),I=009,012)/  0.01304,  0.01450,  0.01591,  0.01719/
      DATA (EPS(I,5),I=013,016)/  0.01822,  0.01896,  0.01952,  0.02004/
      DATA (EPS(I,5),I=017,020)/  0.02060,  0.02116,  0.02170,  0.02220/
      DATA (EPS(I,5),I=021,024)/  0.02259,  0.02287,  0.02300,  0.02300/
      DATA (EPS(I,5),I=025,028)/  0.02289,  0.02270,  0.02245,  0.02215/
      DATA (EPS(I,5),I=029,032)/  0.02184,  0.02154,  0.02126,  0.02101/
      DATA (EPS(I,5),I=033,036)/  0.02079,  0.02061,  0.02045,  0.02030/
      DATA (EPS(I,5),I=037,040)/  0.02017,  0.02005,  0.01994,  0.01985/
      DATA (EPS(I,5),I=041,044)/  0.01979,  0.01972,  0.01969,  0.01966/
      DATA (EPS(I,5),I=045,048)/  0.01966,  0.01968,  0.01971,  0.01975/
      DATA (EPS(I,5),I=049,052)/  0.01982,  0.01989,  0.01997,  0.02006/
      DATA (EPS(I,5),I=053,056)/  0.02016,  0.02028,  0.02040,  0.02054/
      DATA (EPS(I,5),I=057,060)/  0.02067,  0.02083,  0.02099,  0.02116/
      DATA (EPS(I,5),I=061,064)/  0.02135,  0.02155,  0.02175,  0.02198/
      DATA (EPS(I,5),I=065,068)/  0.02221,  0.02245,  0.02271,  0.02298/
      DATA (EPS(I,5),I=069,072)/  0.02325,  0.02355,  0.02386,  0.02417/
      DATA (EPS(I,5),I=073,076)/  0.02450,  0.02484,  0.02519,  0.02555/
      DATA (EPS(I,5),I=077,080)/  0.02592,  0.02630,  0.02670,  0.02710/
      DATA (EPS(I,5),I=081,084)/  0.02752,  0.02795,  0.02839,  0.02884/
      DATA (EPS(I,5),I=085,088)/  0.02929,  0.02976,  0.03025,  0.03075/
      DATA (EPS(I,5),I=089,092)/  0.03126,  0.03178,  0.03232,  0.03287/
      DATA (EPS(I,5),I=093,096)/  0.03343,  0.03401,  0.03461,  0.03522/
      DATA (EPS(I,5),I=097,100)/  0.03585,  0.03648,  0.03714,  0.03782/
      DATA (EPS(I,5),I=101,104)/  0.03849,  0.03920,  0.03991,  0.04063/
      DATA (EPS(I,5),I=105,108)/  0.04136,  0.04213,  0.04290,  0.04369/
      DATA (EPS(I,5),I=109,112)/  0.04451,  0.04535,  0.04622,  0.04712/
      DATA (EPS(I,5),I=113,116)/  0.04803,  0.04898,  0.04994,  0.05092/
      DATA (EPS(I,5),I=117,120)/  0.05192,  0.05294,  0.05397,  0.05503/
      DATA (EPS(I,5),I=121,124)/  0.05610,  0.05721,  0.05833,  0.05949/
      DATA (EPS(I,5),I=125,128)/  0.06067,  0.06187,  0.06309,  0.06434/
      DATA (EPS(I,5),I=129,132)/  0.06559,  0.06687,  0.06814,  0.06944/
      DATA (EPS(I,5),I=133,136)/  0.07073,  0.07201,  0.07327,  0.07450/
      DATA (EPS(I,5),I=137,140)/  0.07571,  0.07689,  0.07801,  0.07908/
      DATA (EPS(I,5),I=141,144)/  0.08009,  0.08104,  0.08194,  0.08277/
      DATA (EPS(I,5),I=145,148)/  0.08353,  0.08422,  0.08483,  0.08538/
      DATA (EPS(I,5),I=149,152)/  0.08584,  0.08625,  0.08659,  0.08685/
      DATA (EPS(I,5),I=153,156)/  0.08706,  0.08720,  0.08729,  0.08732/
      DATA (EPS(I,5),I=157,160)/  0.08728,  0.08716,  0.08691,  0.08654/
      DATA (EPS(I,5),I=161,164)/  0.08602,  0.08530,  0.08440,  0.08327/
      DATA (EPS(I,5),I=165,168)/  0.08189,  0.08025,  0.07838,  0.07630/
      DATA (EPS(I,5),I=169,172)/  0.07403,  0.07162,  0.06908,  0.06647/
      DATA (EPS(I,5),I=173,176)/  0.06378,  0.06107,  0.05836,  0.05568/
      DATA (EPS(I,5),I=177,180)/  0.05306,  0.05048,  0.04794,  0.04546/
      DATA (EPS(I,5),I=181,184)/  0.04301,  0.04061,  0.03825,  0.03592/
      DATA (EPS(I,5),I=185,188)/  0.03363,  0.03137,  0.02914,  0.02694/
      DATA (EPS(I,5),I=189,192)/  0.02477,  0.02262,  0.02049,  0.01838/
      DATA (EPS(I,5),I=193,196)/  0.01630,  0.01422,  0.01216,  0.01011/
      DATA (EPS(I,5),I=197,200)/  0.00808,  0.00605,  0.00403,  0.00201/
      DATA  EPS(201,5)         /  0.00000  /
************************************************************************
      DATA (EPS(I,6),I=001,004)/  0.00000,  0.00149,  0.00297,  0.00444/
      DATA (EPS(I,6),I=005,008)/  0.00589,  0.00734,  0.00875,  0.01013/
      DATA (EPS(I,6),I=009,012)/  0.01148,  0.01279,  0.01405,  0.01512/
      DATA (EPS(I,6),I=013,016)/  0.01582,  0.01616,  0.01631,  0.01642/
      DATA (EPS(I,6),I=017,020)/  0.01659,  0.01681,  0.01705,  0.01729/
      DATA (EPS(I,6),I=021,024)/  0.01751,  0.01767,  0.01778,  0.01784/
      DATA (EPS(I,6),I=025,028)/  0.01787,  0.01787,  0.01788,  0.01788/
      DATA (EPS(I,6),I=029,032)/  0.01793,  0.01800,  0.01813,  0.01831/
      DATA (EPS(I,6),I=033,036)/  0.01854,  0.01881,  0.01912,  0.01945/
      DATA (EPS(I,6),I=037,040)/  0.01981,  0.02018,  0.02056,  0.02095/
      DATA (EPS(I,6),I=041,044)/  0.02134,  0.02175,  0.02216,  0.02257/
      DATA (EPS(I,6),I=045,048)/  0.02299,  0.02342,  0.02385,  0.02429/
      DATA (EPS(I,6),I=049,052)/  0.02475,  0.02521,  0.02569,  0.02619/
      DATA (EPS(I,6),I=053,056)/  0.02670,  0.02722,  0.02777,  0.02832/
      DATA (EPS(I,6),I=057,060)/  0.02889,  0.02947,  0.03005,  0.03065/
      DATA (EPS(I,6),I=061,064)/  0.03125,  0.03186,  0.03247,  0.03308/
      DATA (EPS(I,6),I=065,068)/  0.03370,  0.03432,  0.03495,  0.03559/
      DATA (EPS(I,6),I=069,072)/  0.03625,  0.03692,  0.03759,  0.03828/
      DATA (EPS(I,6),I=073,076)/  0.03898,  0.03969,  0.04041,  0.04114/
      DATA (EPS(I,6),I=077,080)/  0.04189,  0.04265,  0.04341,  0.04419/
      DATA (EPS(I,6),I=081,084)/  0.04496,  0.04574,  0.04651,  0.04729/
      DATA (EPS(I,6),I=085,088)/  0.04804,  0.04879,  0.04953,  0.05026/
      DATA (EPS(I,6),I=089,092)/  0.05100,  0.05171,  0.05243,  0.05314/
      DATA (EPS(I,6),I=093,096)/  0.05386,  0.05456,  0.05525,  0.05594/
      DATA (EPS(I,6),I=097,100)/  0.05661,  0.05728,  0.05793,  0.05858/
      DATA (EPS(I,6),I=101,104)/  0.05921,  0.05981,  0.06039,  0.06096/
      DATA (EPS(I,6),I=105,108)/  0.06149,  0.06200,  0.06248,  0.06295/
      DATA (EPS(I,6),I=109,112)/  0.06339,  0.06381,  0.06422,  0.06461/
      DATA (EPS(I,6),I=113,116)/  0.06498,  0.06533,  0.06566,  0.06597/
      DATA (EPS(I,6),I=117,120)/  0.06626,  0.06651,  0.06675,  0.06695/
      DATA (EPS(I,6),I=121,124)/  0.06714,  0.06729,  0.06740,  0.06749/
      DATA (EPS(I,6),I=125,128)/  0.06754,  0.06755,  0.06754,  0.06751/
      DATA (EPS(I,6),I=129,132)/  0.06743,  0.06734,  0.06720,  0.06704/
      DATA (EPS(I,6),I=133,136)/  0.06686,  0.06666,  0.06642,  0.06615/
      DATA (EPS(I,6),I=137,140)/  0.06586,  0.06554,  0.06520,  0.06481/
      DATA (EPS(I,6),I=141,144)/  0.06441,  0.06397,  0.06351,  0.06303/
      DATA (EPS(I,6),I=145,148)/  0.06252,  0.06198,  0.06142,  0.06083/
      DATA (EPS(I,6),I=149,152)/  0.06022,  0.05960,  0.05896,  0.05830/
      DATA (EPS(I,6),I=153,156)/  0.05763,  0.05695,  0.05626,  0.05555/
      DATA (EPS(I,6),I=157,160)/  0.05482,  0.05406,  0.05325,  0.05241/
      DATA (EPS(I,6),I=161,164)/  0.05152,  0.05057,  0.04956,  0.04848/
      DATA (EPS(I,6),I=165,168)/  0.04734,  0.04615,  0.04490,  0.04362/
      DATA (EPS(I,6),I=169,172)/  0.04231,  0.04095,  0.03959,  0.03820/
      DATA (EPS(I,6),I=173,176)/  0.03681,  0.03542,  0.03404,  0.03266/
      DATA (EPS(I,6),I=177,180)/  0.03129,  0.02993,  0.02857,  0.02723/
      DATA (EPS(I,6),I=181,184)/  0.02589,  0.02455,  0.02322,  0.02190/
      DATA (EPS(I,6),I=185,188)/  0.02058,  0.01927,  0.01797,  0.01667/
      DATA (EPS(I,6),I=189,192)/  0.01537,  0.01408,  0.01279,  0.01150/
      DATA (EPS(I,6),I=193,196)/  0.01021,  0.00893,  0.00765,  0.00637/
      DATA (EPS(I,6),I=197,200)/  0.00509,  0.00382,  0.00254,  0.00127/
      DATA  EPS(201,6)         /  0.00000  /
************************************************************************
      DATA (EPS(I,7),I=001,004)/  0.00000,  0.00159,  0.00318,  0.00476/
      DATA (EPS(I,7),I=005,008)/  0.00632,  0.00786,  0.00937,  0.01086/
      DATA (EPS(I,7),I=009,012)/  0.01231,  0.01372,  0.01507,  0.01623/
      DATA (EPS(I,7),I=013,016)/  0.01702,  0.01743,  0.01761,  0.01776/
      DATA (EPS(I,7),I=017,020)/  0.01797,  0.01823,  0.01851,  0.01877/
      DATA (EPS(I,7),I=021,024)/  0.01899,  0.01914,  0.01920,  0.01918/
      DATA (EPS(I,7),I=025,028)/  0.01911,  0.01898,  0.01885,  0.01871/
      DATA (EPS(I,7),I=029,032)/  0.01858,  0.01850,  0.01846,  0.01848/
      DATA (EPS(I,7),I=033,036)/  0.01855,  0.01867,  0.01882,  0.01900/
      DATA (EPS(I,7),I=037,040)/  0.01919,  0.01940,  0.01962,  0.01986/
      DATA (EPS(I,7),I=041,044)/  0.02010,  0.02036,  0.02062,  0.02088/
      DATA (EPS(I,7),I=045,048)/  0.02115,  0.02144,  0.02174,  0.02205/
      DATA (EPS(I,7),I=049,052)/  0.02237,  0.02271,  0.02306,  0.02343/
      DATA (EPS(I,7),I=053,056)/  0.02382,  0.02423,  0.02465,  0.02509/
      DATA (EPS(I,7),I=057,060)/  0.02555,  0.02602,  0.02650,  0.02699/
      DATA (EPS(I,7),I=061,064)/  0.02749,  0.02800,  0.02850,  0.02902/
      DATA (EPS(I,7),I=065,068)/  0.02956,  0.03009,  0.03065,  0.03121/
      DATA (EPS(I,7),I=069,072)/  0.03177,  0.03236,  0.03295,  0.03357/
      DATA (EPS(I,7),I=073,076)/  0.03420,  0.03484,  0.03550,  0.03618/
      DATA (EPS(I,7),I=077,080)/  0.03688,  0.03760,  0.03833,  0.03908/
      DATA (EPS(I,7),I=081,084)/  0.03984,  0.04061,  0.04139,  0.04217/
      DATA (EPS(I,7),I=085,088)/  0.04295,  0.04374,  0.04453,  0.04532/
      DATA (EPS(I,7),I=089,092)/  0.04612,  0.04691,  0.04772,  0.04852/
      DATA (EPS(I,7),I=093,096)/  0.04932,  0.05013,  0.05094,  0.05172/
      DATA (EPS(I,7),I=097,100)/  0.05252,  0.05329,  0.05406,  0.05482/
      DATA (EPS(I,7),I=101,104)/  0.05554,  0.05626,  0.05695,  0.05761/
      DATA (EPS(I,7),I=105,108)/  0.05824,  0.05884,  0.05942,  0.05997/
      DATA (EPS(I,7),I=109,112)/  0.06049,  0.06099,  0.06147,  0.06193/
      DATA (EPS(I,7),I=113,116)/  0.06237,  0.06280,  0.06320,  0.06357/
      DATA (EPS(I,7),I=117,120)/  0.06393,  0.06426,  0.06456,  0.06484/
      DATA (EPS(I,7),I=121,124)/  0.06508,  0.06530,  0.06548,  0.06564/
      DATA (EPS(I,7),I=125,128)/  0.06576,  0.06585,  0.06591,  0.06595/
      DATA (EPS(I,7),I=129,132)/  0.06594,  0.06592,  0.06586,  0.06578/
      DATA (EPS(I,7),I=133,136)/  0.06567,  0.06553,  0.06537,  0.06517/
      DATA (EPS(I,7),I=137,140)/  0.06496,  0.06470,  0.06442,  0.06410/
      DATA (EPS(I,7),I=141,144)/  0.06376,  0.06339,  0.06299,  0.06257/
      DATA (EPS(I,7),I=145,148)/  0.06210,  0.06161,  0.06110,  0.06056/
      DATA (EPS(I,7),I=149,152)/  0.06000,  0.05942,  0.05881,  0.05819/
      DATA (EPS(I,7),I=153,156)/  0.05756,  0.05691,  0.05625,  0.05557/
      DATA (EPS(I,7),I=157,160)/  0.05487,  0.05413,  0.05336,  0.05254/
      DATA (EPS(I,7),I=161,164)/  0.05168,  0.05075,  0.04977,  0.04871/
      DATA (EPS(I,7),I=165,168)/  0.04760,  0.04643,  0.04521,  0.04395/
      DATA (EPS(I,7),I=169,172)/  0.04265,  0.04132,  0.03997,  0.03860/
      DATA (EPS(I,7),I=173,176)/  0.03722,  0.03584,  0.03446,  0.03309/
      DATA (EPS(I,7),I=177,180)/  0.03172,  0.03036,  0.02900,  0.02765/
      DATA (EPS(I,7),I=181,184)/  0.02630,  0.02496,  0.02362,  0.02229/
      DATA (EPS(I,7),I=185,188)/  0.02095,  0.01963,  0.01831,  0.01699/
      DATA (EPS(I,7),I=189,192)/  0.01567,  0.01436,  0.01304,  0.01173/
      DATA (EPS(I,7),I=193,196)/  0.01042,  0.00912,  0.00781,  0.00651/
      DATA (EPS(I,7),I=197,200)/  0.00521,  0.00390,  0.00260,  0.00130/
      DATA  EPS(201,7)         /  0.00000  /
************************************************************************
      DATA (EPS(I,8),I=001,004)/  0.00000,  0.00148,  0.00296,  0.00443/
      DATA (EPS(I,8),I=005,008)/  0.00588,  0.00733,  0.00874,  0.01014/
      DATA (EPS(I,8),I=009,012)/  0.01151,  0.01284,  0.01413,  0.01523/
      DATA (EPS(I,8),I=013,016)/  0.01598,  0.01638,  0.01659,  0.01676/
      DATA (EPS(I,8),I=017,020)/  0.01700,  0.01728,  0.01756,  0.01783/
      DATA (EPS(I,8),I=021,024)/  0.01804,  0.01816,  0.01819,  0.01811/
      DATA (EPS(I,8),I=025,028)/  0.01796,  0.01775,  0.01752,  0.01724/
      DATA (EPS(I,8),I=029,032)/  0.01695,  0.01668,  0.01642,  0.01619/
      DATA (EPS(I,8),I=033,036)/  0.01599,  0.01581,  0.01567,  0.01556/
      DATA (EPS(I,8),I=037,040)/  0.01548,  0.01543,  0.01541,  0.01541/
      DATA (EPS(I,8),I=041,044)/  0.01545,  0.01551,  0.01559,  0.01570/
      DATA (EPS(I,8),I=045,048)/  0.01583,  0.01598,  0.01616,  0.01635/
      DATA (EPS(I,8),I=049,052)/  0.01657,  0.01682,  0.01708,  0.01737/
      DATA (EPS(I,8),I=053,056)/  0.01769,  0.01802,  0.01837,  0.01874/
      DATA (EPS(I,8),I=057,060)/  0.01913,  0.01952,  0.01992,  0.02033/
      DATA (EPS(I,8),I=061,064)/  0.02075,  0.02115,  0.02157,  0.02199/
      DATA (EPS(I,8),I=065,068)/  0.02241,  0.02285,  0.02329,  0.02376/
      DATA (EPS(I,8),I=069,072)/  0.02423,  0.02472,  0.02522,  0.02575/
      DATA (EPS(I,8),I=073,076)/  0.02629,  0.02685,  0.02742,  0.02802/
      DATA (EPS(I,8),I=077,080)/  0.02863,  0.02926,  0.02990,  0.03055/
      DATA (EPS(I,8),I=081,084)/  0.03122,  0.03188,  0.03254,  0.03322/
      DATA (EPS(I,8),I=085,088)/  0.03388,  0.03455,  0.03523,  0.03591/
      DATA (EPS(I,8),I=089,092)/  0.03661,  0.03732,  0.03806,  0.03881/
      DATA (EPS(I,8),I=093,096)/  0.03958,  0.04036,  0.04115,  0.04197/
      DATA (EPS(I,8),I=097,100)/  0.04278,  0.04361,  0.04445,  0.04527/
      DATA (EPS(I,8),I=101,104)/  0.04610,  0.04692,  0.04772,  0.04851/
      DATA (EPS(I,8),I=105,108)/  0.04928,  0.05004,  0.05077,  0.05149/
      DATA (EPS(I,8),I=109,112)/  0.05219,  0.05288,  0.05356,  0.05422/
      DATA (EPS(I,8),I=113,116)/  0.05487,  0.05550,  0.05612,  0.05670/
      DATA (EPS(I,8),I=117,120)/  0.05728,  0.05782,  0.05834,  0.05884/
      DATA (EPS(I,8),I=121,124)/  0.05931,  0.05975,  0.06015,  0.06053/
      DATA (EPS(I,8),I=125,128)/  0.06086,  0.06117,  0.06144,  0.06169/
      DATA (EPS(I,8),I=129,132)/  0.06190,  0.06210,  0.06227,  0.06241/
      DATA (EPS(I,8),I=133,136)/  0.06254,  0.06263,  0.06271,  0.06275/
      DATA (EPS(I,8),I=137,140)/  0.06277,  0.06275,  0.06271,  0.06264/
      DATA (EPS(I,8),I=141,144)/  0.06254,  0.06240,  0.06222,  0.06201/
      DATA (EPS(I,8),I=145,148)/  0.06176,  0.06147,  0.06115,  0.06077/
      DATA (EPS(I,8),I=149,152)/  0.06037,  0.05994,  0.05948,  0.05899/
      DATA (EPS(I,8),I=153,156)/  0.05849,  0.05797,  0.05741,  0.05685/
      DATA (EPS(I,8),I=157,160)/  0.05625,  0.05562,  0.05494,  0.05421/
      DATA (EPS(I,8),I=161,164)/  0.05343,  0.05260,  0.05169,  0.05072/
      DATA (EPS(I,8),I=165,168)/  0.04968,  0.04857,  0.04740,  0.04619/
      DATA (EPS(I,8),I=169,172)/  0.04494,  0.04365,  0.04234,  0.04098/
      DATA (EPS(I,8),I=173,176)/  0.03962,  0.03824,  0.03685,  0.03546/
      DATA (EPS(I,8),I=177,180)/  0.03407,  0.03268,  0.03128,  0.02988/
      DATA (EPS(I,8),I=181,184)/  0.02847,  0.02706,  0.02565,  0.02424/
      DATA (EPS(I,8),I=185,188)/  0.02282,  0.02141,  0.01999,  0.01857/
      DATA (EPS(I,8),I=189,192)/  0.01715,  0.01573,  0.01430,  0.01287/
      DATA (EPS(I,8),I=193,196)/  0.01144,  0.01002,  0.00859,  0.00716/
      DATA (EPS(I,8),I=197,200)/  0.00573,  0.00430,  0.00286,  0.00143/
      DATA  EPS(201,8)         /  0.00000  /
************************************************************************
************************************************************************
      DATA (PSI(I,1),I=001,004)/  0.15066,  0.15058,  0.15035,  0.14999/
      DATA (PSI(I,1),I=005,008)/  0.14950,  0.14891,  0.14823,  0.14748/
      DATA (PSI(I,1),I=009,012)/  0.14668,  0.14583,  0.14497,  0.14410/
      DATA (PSI(I,1),I=013,016)/  0.14323,  0.14238,  0.14155,  0.14074/
      DATA (PSI(I,1),I=017,020)/  0.13998,  0.13927,  0.13862,  0.13804/
      DATA (PSI(I,1),I=021,024)/  0.13753,  0.13711,  0.13676,  0.13648/
      DATA (PSI(I,1),I=025,028)/  0.13627,  0.13610,  0.13598,  0.13590/
      DATA (PSI(I,1),I=029,032)/  0.13584,  0.13579,  0.13576,  0.13573/
      DATA (PSI(I,1),I=033,036)/  0.13570,  0.13567,  0.13564,  0.13561/
      DATA (PSI(I,1),I=037,040)/  0.13558,  0.13555,  0.13552,  0.13550/
      DATA (PSI(I,1),I=041,044)/  0.13547,  0.13544,  0.13542,  0.13539/
      DATA (PSI(I,1),I=045,048)/  0.13536,  0.13533,  0.13529,  0.13525/
      DATA (PSI(I,1),I=049,052)/  0.13521,  0.13516,  0.13511,  0.13505/
      DATA (PSI(I,1),I=053,056)/  0.13499,  0.13491,  0.13483,  0.13475/
      DATA (PSI(I,1),I=057,060)/  0.13465,  0.13454,  0.13442,  0.13428/
      DATA (PSI(I,1),I=061,064)/  0.13414,  0.13398,  0.13381,  0.13363/
      DATA (PSI(I,1),I=065,068)/  0.13343,  0.13321,  0.13299,  0.13275/
      DATA (PSI(I,1),I=069,072)/  0.13249,  0.13222,  0.13194,  0.13164/
      DATA (PSI(I,1),I=073,076)/  0.13133,  0.13100,  0.13065,  0.13028/
      DATA (PSI(I,1),I=077,080)/  0.12988,  0.12947,  0.12903,  0.12857/
      DATA (PSI(I,1),I=081,084)/  0.12808,  0.12756,  0.12702,  0.12644/
      DATA (PSI(I,1),I=085,088)/  0.12584,  0.12521,  0.12455,  0.12385/
      DATA (PSI(I,1),I=089,092)/  0.12313,  0.12238,  0.12160,  0.12079/
      DATA (PSI(I,1),I=093,096)/  0.11994,  0.11907,  0.11817,  0.11724/
      DATA (PSI(I,1),I=097,100)/  0.11628,  0.11529,  0.11428,  0.11324/
      DATA (PSI(I,1),I=101,104)/  0.11218,  0.11109,  0.10998,  0.10884/
      DATA (PSI(I,1),I=105,108)/  0.10768,  0.10650,  0.10530,  0.10407/
      DATA (PSI(I,1),I=109,112)/  0.10283,  0.10157,  0.10029,  0.09899/
      DATA (PSI(I,1),I=113,116)/  0.09767,  0.09634,  0.09499,  0.09363/
      DATA (PSI(I,1),I=117,120)/  0.09224,  0.09085,  0.08944,  0.08801/
      DATA (PSI(I,1),I=121,124)/  0.08657,  0.08512,  0.08365,  0.08217/
      DATA (PSI(I,1),I=125,128)/  0.08068,  0.07917,  0.07766,  0.07614/
      DATA (PSI(I,1),I=129,132)/  0.07461,  0.07307,  0.07153,  0.06998/
      DATA (PSI(I,1),I=133,136)/  0.06842,  0.06687,  0.06530,  0.06374/
      DATA (PSI(I,1),I=137,140)/  0.06217,  0.06060,  0.05904,  0.05747/
      DATA (PSI(I,1),I=141,144)/  0.05591,  0.05435,  0.05280,  0.05125/
      DATA (PSI(I,1),I=145,148)/  0.04970,  0.04817,  0.04664,  0.04512/
      DATA (PSI(I,1),I=149,152)/  0.04362,  0.04213,  0.04065,  0.03919/
      DATA (PSI(I,1),I=153,156)/  0.03774,  0.03631,  0.03490,  0.03350/
      DATA (PSI(I,1),I=157,160)/  0.03213,  0.03077,  0.02943,  0.02811/
      DATA (PSI(I,1),I=161,164)/  0.02682,  0.02555,  0.02430,  0.02308/
      DATA (PSI(I,1),I=165,168)/  0.02188,  0.02071,  0.01956,  0.01844/
      DATA (PSI(I,1),I=169,172)/  0.01735,  0.01630,  0.01527,  0.01428/
      DATA (PSI(I,1),I=173,176)/  0.01331,  0.01239,  0.01149,  0.01062/
      DATA (PSI(I,1),I=177,180)/  0.00979,  0.00899,  0.00823,  0.00750/
      DATA (PSI(I,1),I=181,184)/  0.00680,  0.00614,  0.00551,  0.00491/
      DATA (PSI(I,1),I=185,188)/  0.00435,  0.00382,  0.00332,  0.00286/
      DATA (PSI(I,1),I=189,192)/  0.00244,  0.00205,  0.00169,  0.00137/
      DATA (PSI(I,1),I=193,196)/  0.00108,  0.00083,  0.00061,  0.00042/
      DATA (PSI(I,1),I=197,200)/  0.00027,  0.00015,  0.00007,  0.00002/
      DATA  PSI(201,1)         /  0.00000  /
************************************************************************
      DATA (PSI(I,2),I=001,004)/  0.25269,  0.25265,  0.25251,  0.25227/
      DATA (PSI(I,2),I=005,008)/  0.25193,  0.25147,  0.25090,  0.25020/
      DATA (PSI(I,2),I=009,012)/  0.24937,  0.24841,  0.24730,  0.24605/
      DATA (PSI(I,2),I=013,016)/  0.24467,  0.24321,  0.24170,  0.24016/
      DATA (PSI(I,2),I=017,020)/  0.23864,  0.23715,  0.23573,  0.23442/
      DATA (PSI(I,2),I=021,024)/  0.23325,  0.23224,  0.23138,  0.23066/
      DATA (PSI(I,2),I=025,028)/  0.23006,  0.22956,  0.22916,  0.22884/
      DATA (PSI(I,2),I=029,032)/  0.22858,  0.22836,  0.22818,  0.22802/
      DATA (PSI(I,2),I=033,036)/  0.22788,  0.22775,  0.22764,  0.22755/
      DATA (PSI(I,2),I=037,040)/  0.22747,  0.22740,  0.22736,  0.22732/
      DATA (PSI(I,2),I=041,044)/  0.22730,  0.22729,  0.22730,  0.22731/
      DATA (PSI(I,2),I=045,048)/  0.22733,  0.22736,  0.22739,  0.22742/
      DATA (PSI(I,2),I=049,052)/  0.22745,  0.22748,  0.22751,  0.22753/
      DATA (PSI(I,2),I=053,056)/  0.22755,  0.22756,  0.22756,  0.22755/
      DATA (PSI(I,2),I=057,060)/  0.22753,  0.22751,  0.22747,  0.22742/
      DATA (PSI(I,2),I=061,064)/  0.22736,  0.22729,  0.22720,  0.22709/
      DATA (PSI(I,2),I=065,068)/  0.22697,  0.22683,  0.22668,  0.22650/
      DATA (PSI(I,2),I=069,072)/  0.22630,  0.22608,  0.22584,  0.22557/
      DATA (PSI(I,2),I=073,076)/  0.22528,  0.22497,  0.22462,  0.22426/
      DATA (PSI(I,2),I=077,080)/  0.22386,  0.22345,  0.22300,  0.22253/
      DATA (PSI(I,2),I=081,084)/  0.22203,  0.22150,  0.22094,  0.22034/
      DATA (PSI(I,2),I=085,088)/  0.21969,  0.21899,  0.21823,  0.21741/
      DATA (PSI(I,2),I=089,092)/  0.21652,  0.21554,  0.21449,  0.21334/
      DATA (PSI(I,2),I=093,096)/  0.21211,  0.21081,  0.20941,  0.20795/
      DATA (PSI(I,2),I=097,100)/  0.20642,  0.20482,  0.20316,  0.20143/
      DATA (PSI(I,2),I=101,104)/  0.19966,  0.19784,  0.19597,  0.19406/
      DATA (PSI(I,2),I=105,108)/  0.19210,  0.19009,  0.18805,  0.18597/
      DATA (PSI(I,2),I=109,112)/  0.18385,  0.18169,  0.17950,  0.17727/
      DATA (PSI(I,2),I=113,116)/  0.17502,  0.17274,  0.17042,  0.16807/
      DATA (PSI(I,2),I=117,120)/  0.16570,  0.16330,  0.16087,  0.15843/
      DATA (PSI(I,2),I=121,124)/  0.15596,  0.15347,  0.15095,  0.14842/
      DATA (PSI(I,2),I=125,128)/  0.14588,  0.14331,  0.14073,  0.13812/
      DATA (PSI(I,2),I=129,132)/  0.13551,  0.13288,  0.13024,  0.12759/
      DATA (PSI(I,2),I=133,136)/  0.12492,  0.12225,  0.11957,  0.11688/
      DATA (PSI(I,2),I=137,140)/  0.11418,  0.11149,  0.10878,  0.10608/
      DATA (PSI(I,2),I=141,144)/  0.10338,  0.10068,  0.09798,  0.09529/
      DATA (PSI(I,2),I=145,148)/  0.09260,  0.08992,  0.08725,  0.08459/
      DATA (PSI(I,2),I=149,152)/  0.08195,  0.07932,  0.07671,  0.07412/
      DATA (PSI(I,2),I=153,156)/  0.07155,  0.06900,  0.06648,  0.06398/
      DATA (PSI(I,2),I=157,160)/  0.06151,  0.05907,  0.05666,  0.05428/
      DATA (PSI(I,2),I=161,164)/  0.05193,  0.04962,  0.04733,  0.04509/
      DATA (PSI(I,2),I=165,168)/  0.04288,  0.04072,  0.03859,  0.03650/
      DATA (PSI(I,2),I=169,172)/  0.03446,  0.03247,  0.03051,  0.02861/
      DATA (PSI(I,2),I=173,176)/  0.02674,  0.02493,  0.02317,  0.02147/
      DATA (PSI(I,2),I=177,180)/  0.01982,  0.01824,  0.01672,  0.01525/
      DATA (PSI(I,2),I=181,184)/  0.01385,  0.01252,  0.01125,  0.01006/
      DATA (PSI(I,2),I=185,188)/  0.00892,  0.00786,  0.00686,  0.00593/
      DATA (PSI(I,2),I=189,192)/  0.00506,  0.00426,  0.00353,  0.00287/
      DATA (PSI(I,2),I=193,196)/  0.00227,  0.00174,  0.00128,  0.00089/
      DATA (PSI(I,2),I=197,200)/  0.00057,  0.00032,  0.00014,  0.00004/
      DATA  PSI(201,2)         /  0.00000  /
************************************************************************
      DATA (PSI(I,3),I=001,004)/  0.17464,  0.17456,  0.17434,  0.17397/
      DATA (PSI(I,3),I=005,008)/  0.17348,  0.17285,  0.17211,  0.17125/
      DATA (PSI(I,3),I=009,012)/  0.17030,  0.16923,  0.16808,  0.16682/
      DATA (PSI(I,3),I=013,016)/  0.16542,  0.16391,  0.16236,  0.16086/
      DATA (PSI(I,3),I=017,020)/  0.15949,  0.15823,  0.15711,  0.15610/
      DATA (PSI(I,3),I=021,024)/  0.15523,  0.15451,  0.15390,  0.15343/
      DATA (PSI(I,3),I=025,028)/  0.15305,  0.15278,  0.15258,  0.15246/
      DATA (PSI(I,3),I=029,032)/  0.15239,  0.15235,  0.15235,  0.15237/
      DATA (PSI(I,3),I=033,036)/  0.15241,  0.15249,  0.15258,  0.15269/
      DATA (PSI(I,3),I=037,040)/  0.15282,  0.15297,  0.15314,  0.15331/
      DATA (PSI(I,3),I=041,044)/  0.15350,  0.15370,  0.15389,  0.15408/
      DATA (PSI(I,3),I=045,048)/  0.15427,  0.15445,  0.15464,  0.15482/
      DATA (PSI(I,3),I=049,052)/  0.15501,  0.15518,  0.15536,  0.15553/
      DATA (PSI(I,3),I=053,056)/  0.15569,  0.15585,  0.15600,  0.15615/
      DATA (PSI(I,3),I=057,060)/  0.15629,  0.15643,  0.15655,  0.15667/
      DATA (PSI(I,3),I=061,064)/  0.15678,  0.15688,  0.15697,  0.15705/
      DATA (PSI(I,3),I=065,068)/  0.15711,  0.15718,  0.15723,  0.15726/
      DATA (PSI(I,3),I=069,072)/  0.15729,  0.15731,  0.15731,  0.15730/
      DATA (PSI(I,3),I=073,076)/  0.15728,  0.15724,  0.15719,  0.15713/
      DATA (PSI(I,3),I=077,080)/  0.15704,  0.15694,  0.15682,  0.15669/
      DATA (PSI(I,3),I=081,084)/  0.15653,  0.15637,  0.15618,  0.15598/
      DATA (PSI(I,3),I=085,088)/  0.15576,  0.15552,  0.15526,  0.15498/
      DATA (PSI(I,3),I=089,092)/  0.15466,  0.15431,  0.15393,  0.15351/
      DATA (PSI(I,3),I=093,096)/  0.15305,  0.15255,  0.15200,  0.15141/
      DATA (PSI(I,3),I=097,100)/  0.15078,  0.15011,  0.14938,  0.14862/
      DATA (PSI(I,3),I=101,104)/  0.14779,  0.14693,  0.14602,  0.14505/
      DATA (PSI(I,3),I=105,108)/  0.14402,  0.14295,  0.14181,  0.14063/
      DATA (PSI(I,3),I=109,112)/  0.13940,  0.13812,  0.13680,  0.13544/
      DATA (PSI(I,3),I=113,116)/  0.13403,  0.13259,  0.13110,  0.12958/
      DATA (PSI(I,3),I=117,120)/  0.12804,  0.12646,  0.12484,  0.12320/
      DATA (PSI(I,3),I=121,124)/  0.12154,  0.11984,  0.11813,  0.11638/
      DATA (PSI(I,3),I=125,128)/  0.11461,  0.11281,  0.11100,  0.10915/
      DATA (PSI(I,3),I=129,132)/  0.10730,  0.10541,  0.10353,  0.10161/
      DATA (PSI(I,3),I=133,136)/  0.09970,  0.09778,  0.09583,  0.09389/
      DATA (PSI(I,3),I=137,140)/  0.09194,  0.08998,  0.08800,  0.08601/
      DATA (PSI(I,3),I=141,144)/  0.08401,  0.08201,  0.08000,  0.07798/
      DATA (PSI(I,3),I=145,148)/  0.07596,  0.07393,  0.07191,  0.06989/
      DATA (PSI(I,3),I=149,152)/  0.06788,  0.06586,  0.06385,  0.06185/
      DATA (PSI(I,3),I=153,156)/  0.05986,  0.05787,  0.05589,  0.05392/
      DATA (PSI(I,3),I=157,160)/  0.05196,  0.05001,  0.04807,  0.04615/
      DATA (PSI(I,3),I=161,164)/  0.04422,  0.04232,  0.04042,  0.03854/
      DATA (PSI(I,3),I=165,168)/  0.03667,  0.03481,  0.03297,  0.03115/
      DATA (PSI(I,3),I=169,172)/  0.02937,  0.02762,  0.02590,  0.02423/
      DATA (PSI(I,3),I=173,176)/  0.02260,  0.02101,  0.01949,  0.01802/
      DATA (PSI(I,3),I=177,180)/  0.01661,  0.01526,  0.01396,  0.01272/
      DATA (PSI(I,3),I=181,184)/  0.01154,  0.01042,  0.00935,  0.00834/
      DATA (PSI(I,3),I=185,188)/  0.00739,  0.00650,  0.00566,  0.00489/
      DATA (PSI(I,3),I=189,192)/  0.00416,  0.00350,  0.00289,  0.00234/
      DATA (PSI(I,3),I=193,196)/  0.00185,  0.00141,  0.00104,  0.00072/
      DATA (PSI(I,3),I=197,200)/  0.00046,  0.00026,  0.00012,  0.00003/
      DATA  PSI(201,3)         /  0.00000  /
************************************************************************
      DATA (PSI(I,4),I=001,004)/  0.16457,  0.16455,  0.16449,  0.16437/
      DATA (PSI(I,4),I=005,008)/  0.16416,  0.16386,  0.16345,  0.16292/
      DATA (PSI(I,4),I=009,012)/  0.16223,  0.16139,  0.16037,  0.15916/
      DATA (PSI(I,4),I=013,016)/  0.15779,  0.15631,  0.15475,  0.15316/
      DATA (PSI(I,4),I=017,020)/  0.15157,  0.15002,  0.14856,  0.14722/
      DATA (PSI(I,4),I=021,024)/  0.14604,  0.14506,  0.14427,  0.14364/
      DATA (PSI(I,4),I=025,028)/  0.14316,  0.14281,  0.14257,  0.14242/
      DATA (PSI(I,4),I=029,032)/  0.14235,  0.14233,  0.14236,  0.14241/
      DATA (PSI(I,4),I=033,036)/  0.14248,  0.14257,  0.14267,  0.14280/
      DATA (PSI(I,4),I=037,040)/  0.14294,  0.14310,  0.14327,  0.14346/
      DATA (PSI(I,4),I=041,044)/  0.14366,  0.14387,  0.14410,  0.14433/
      DATA (PSI(I,4),I=045,048)/  0.14457,  0.14481,  0.14506,  0.14530/
      DATA (PSI(I,4),I=049,052)/  0.14554,  0.14578,  0.14601,  0.14623/
      DATA (PSI(I,4),I=053,056)/  0.14645,  0.14665,  0.14685,  0.14704/
      DATA (PSI(I,4),I=057,060)/  0.14722,  0.14740,  0.14757,  0.14774/
      DATA (PSI(I,4),I=061,064)/  0.14790,  0.14806,  0.14821,  0.14835/
      DATA (PSI(I,4),I=065,068)/  0.14849,  0.14862,  0.14875,  0.14886/
      DATA (PSI(I,4),I=069,072)/  0.14897,  0.14908,  0.14917,  0.14925/
      DATA (PSI(I,4),I=073,076)/  0.14933,  0.14940,  0.14945,  0.14950/
      DATA (PSI(I,4),I=077,080)/  0.14954,  0.14957,  0.14959,  0.14961/
      DATA (PSI(I,4),I=081,084)/  0.14961,  0.14960,  0.14959,  0.14956/
      DATA (PSI(I,4),I=085,088)/  0.14953,  0.14948,  0.14943,  0.14936/
      DATA (PSI(I,4),I=089,092)/  0.14928,  0.14918,  0.14908,  0.14896/
      DATA (PSI(I,4),I=093,096)/  0.14883,  0.14869,  0.14853,  0.14835/
      DATA (PSI(I,4),I=097,100)/  0.14816,  0.14796,  0.14774,  0.14750/
      DATA (PSI(I,4),I=101,104)/  0.14725,  0.14698,  0.14669,  0.14638/
      DATA (PSI(I,4),I=105,108)/  0.14606,  0.14571,  0.14533,  0.14494/
      DATA (PSI(I,4),I=109,112)/  0.14452,  0.14407,  0.14360,  0.14310/
      DATA (PSI(I,4),I=113,116)/  0.14256,  0.14198,  0.14135,  0.14067/
      DATA (PSI(I,4),I=117,120)/  0.13992,  0.13910,  0.13820,  0.13722/
      DATA (PSI(I,4),I=121,124)/  0.13615,  0.13498,  0.13371,  0.13237/
      DATA (PSI(I,4),I=125,128)/  0.13094,  0.12943,  0.12787,  0.12624/
      DATA (PSI(I,4),I=129,132)/  0.12457,  0.12284,  0.12108,  0.11929/
      DATA (PSI(I,4),I=133,136)/  0.11746,  0.11561,  0.11374,  0.11183/
      DATA (PSI(I,4),I=137,140)/  0.10988,  0.10790,  0.10590,  0.10386/
      DATA (PSI(I,4),I=141,144)/  0.10180,  0.09970,  0.09758,  0.09542/
      DATA (PSI(I,4),I=145,148)/  0.09325,  0.09106,  0.08885,  0.08662/
      DATA (PSI(I,4),I=149,152)/  0.08439,  0.08214,  0.07989,  0.07763/
      DATA (PSI(I,4),I=153,156)/  0.07537,  0.07311,  0.07085,  0.06859/
      DATA (PSI(I,4),I=157,160)/  0.06633,  0.06407,  0.06182,  0.05957/
      DATA (PSI(I,4),I=161,164)/  0.05733,  0.05510,  0.05287,  0.05066/
      DATA (PSI(I,4),I=165,168)/  0.04845,  0.04627,  0.04411,  0.04196/
      DATA (PSI(I,4),I=169,172)/  0.03983,  0.03773,  0.03566,  0.03362/
      DATA (PSI(I,4),I=173,176)/  0.03160,  0.02963,  0.02769,  0.02579/
      DATA (PSI(I,4),I=177,180)/  0.02394,  0.02214,  0.02038,  0.01869/
      DATA (PSI(I,4),I=181,184)/  0.01705,  0.01547,  0.01396,  0.01249/
      DATA (PSI(I,4),I=185,188)/  0.01111,  0.00980,  0.00856,  0.00740/
      DATA (PSI(I,4),I=189,192)/  0.00631,  0.00531,  0.00439,  0.00356/
      DATA (PSI(I,4),I=193,196)/  0.00281,  0.00216,  0.00159,  0.00110/
      DATA (PSI(I,4),I=197,200)/  0.00071,  0.00040,  0.00018,  0.00004/
      DATA  PSI(201,4)         /  0.00000  /
************************************************************************
      DATA (PSI(I,5),I=001,004)/  0.18028,  0.18026,  0.18017,  0.17999/
      DATA (PSI(I,5),I=005,008)/  0.17970,  0.17927,  0.17866,  0.17786/
      DATA (PSI(I,5),I=009,012)/  0.17684,  0.17558,  0.17403,  0.17233/
      DATA (PSI(I,5),I=013,016)/  0.17077,  0.16944,  0.16824,  0.16708/
      DATA (PSI(I,5),I=017,020)/  0.16586,  0.16461,  0.16334,  0.16208/
      DATA (PSI(I,5),I=021,024)/  0.16085,  0.15968,  0.15859,  0.15759/
      DATA (PSI(I,5),I=025,028)/  0.15667,  0.15583,  0.15506,  0.15438/
      DATA (PSI(I,5),I=029,032)/  0.15377,  0.15323,  0.15278,  0.15240/
      DATA (PSI(I,5),I=033,036)/  0.15207,  0.15179,  0.15156,  0.15135/
      DATA (PSI(I,5),I=037,040)/  0.15115,  0.15097,  0.15079,  0.15063/
      DATA (PSI(I,5),I=041,044)/  0.15048,  0.15035,  0.15023,  0.15012/
      DATA (PSI(I,5),I=045,048)/  0.15004,  0.14997,  0.14992,  0.14988/
      DATA (PSI(I,5),I=049,052)/  0.14985,  0.14983,  0.14982,  0.14982/
      DATA (PSI(I,5),I=053,056)/  0.14982,  0.14983,  0.14985,  0.14986/
      DATA (PSI(I,5),I=057,060)/  0.14989,  0.14992,  0.14995,  0.14999/
      DATA (PSI(I,5),I=061,064)/  0.15002,  0.15006,  0.15010,  0.15014/
      DATA (PSI(I,5),I=065,068)/  0.15019,  0.15023,  0.15027,  0.15032/
      DATA (PSI(I,5),I=069,072)/  0.15036,  0.15041,  0.15046,  0.15050/
      DATA (PSI(I,5),I=073,076)/  0.15056,  0.15060,  0.15066,  0.15070/
      DATA (PSI(I,5),I=077,080)/  0.15076,  0.15081,  0.15085,  0.15090/
      DATA (PSI(I,5),I=081,084)/  0.15095,  0.15098,  0.15101,  0.15103/
      DATA (PSI(I,5),I=085,088)/  0.15106,  0.15108,  0.15108,  0.15109/
      DATA (PSI(I,5),I=089,092)/  0.15110,  0.15110,  0.15110,  0.15110/
      DATA (PSI(I,5),I=093,096)/  0.15109,  0.15108,  0.15106,  0.15103/
      DATA (PSI(I,5),I=097,100)/  0.15100,  0.15096,  0.15090,  0.15084/
      DATA (PSI(I,5),I=101,104)/  0.15076,  0.15068,  0.15059,  0.15050/
      DATA (PSI(I,5),I=105,108)/  0.15038,  0.15026,  0.15014,  0.14999/
      DATA (PSI(I,5),I=109,112)/  0.14983,  0.14965,  0.14945,  0.14924/
      DATA (PSI(I,5),I=113,116)/  0.14900,  0.14875,  0.14847,  0.14817/
      DATA (PSI(I,5),I=117,120)/  0.14784,  0.14750,  0.14712,  0.14671/
      DATA (PSI(I,5),I=121,124)/  0.14628,  0.14582,  0.14532,  0.14479/
      DATA (PSI(I,5),I=125,128)/  0.14422,  0.14362,  0.14296,  0.14226/
      DATA (PSI(I,5),I=129,132)/  0.14149,  0.14065,  0.13974,  0.13875/
      DATA (PSI(I,5),I=133,136)/  0.13768,  0.13652,  0.13526,  0.13391/
      DATA (PSI(I,5),I=137,140)/  0.13246,  0.13090,  0.12925,  0.12748/
      DATA (PSI(I,5),I=141,144)/  0.12560,  0.12366,  0.12163,  0.11954/
      DATA (PSI(I,5),I=145,148)/  0.11738,  0.11520,  0.11298,  0.11074/
      DATA (PSI(I,5),I=149,152)/  0.10848,  0.10618,  0.10386,  0.10150/
      DATA (PSI(I,5),I=153,156)/  0.09911,  0.09667,  0.09420,  0.09168/
      DATA (PSI(I,5),I=157,160)/  0.08911,  0.08650,  0.08384,  0.08115/
      DATA (PSI(I,5),I=161,164)/  0.07840,  0.07562,  0.07280,  0.06994/
      DATA (PSI(I,5),I=165,168)/  0.06704,  0.06412,  0.06117,  0.05820/
      DATA (PSI(I,5),I=169,172)/  0.05524,  0.05228,  0.04935,  0.04644/
      DATA (PSI(I,5),I=173,176)/  0.04358,  0.04078,  0.03803,  0.03536/
      DATA (PSI(I,5),I=177,180)/  0.03277,  0.03026,  0.02785,  0.02551/
      DATA (PSI(I,5),I=181,184)/  0.02327,  0.02112,  0.01906,  0.01710/
      DATA (PSI(I,5),I=185,188)/  0.01522,  0.01345,  0.01178,  0.01021/
      DATA (PSI(I,5),I=189,192)/  0.00875,  0.00740,  0.00615,  0.00501/
      DATA (PSI(I,5),I=193,196)/  0.00397,  0.00306,  0.00226,  0.00158/
      DATA (PSI(I,5),I=197,200)/  0.00101,  0.00057,  0.00025,  0.00006/
      DATA  PSI(201,5)         /  0.00000  /
************************************************************************
      DATA (PSI(I,6),I=001,004)/  0.15517,  0.15505,  0.15472,  0.15418/
      DATA (PSI(I,6),I=005,008)/  0.15346,  0.15257,  0.15154,  0.15038/
      DATA (PSI(I,6),I=009,012)/  0.14911,  0.14776,  0.14634,  0.14493/
      DATA (PSI(I,6),I=013,016)/  0.14363,  0.14249,  0.14146,  0.14058/
      DATA (PSI(I,6),I=017,020)/  0.13979,  0.13911,  0.13851,  0.13799/
      DATA (PSI(I,6),I=021,024)/  0.13753,  0.13713,  0.13678,  0.13647/
      DATA (PSI(I,6),I=025,028)/  0.13620,  0.13596,  0.13576,  0.13559/
      DATA (PSI(I,6),I=029,032)/  0.13543,  0.13531,  0.13521,  0.13512/
      DATA (PSI(I,6),I=033,036)/  0.13505,  0.13499,  0.13493,  0.13488/
      DATA (PSI(I,6),I=037,040)/  0.13484,  0.13480,  0.13476,  0.13471/
      DATA (PSI(I,6),I=041,044)/  0.13468,  0.13463,  0.13460,  0.13456/
      DATA (PSI(I,6),I=045,048)/  0.13452,  0.13447,  0.13442,  0.13438/
      DATA (PSI(I,6),I=049,052)/  0.13432,  0.13427,  0.13420,  0.13414/
      DATA (PSI(I,6),I=053,056)/  0.13406,  0.13399,  0.13390,  0.13380/
      DATA (PSI(I,6),I=057,060)/  0.13371,  0.13360,  0.13348,  0.13336/
      DATA (PSI(I,6),I=061,064)/  0.13322,  0.13307,  0.13292,  0.13276/
      DATA (PSI(I,6),I=065,068)/  0.13258,  0.13239,  0.13220,  0.13198/
      DATA (PSI(I,6),I=069,072)/  0.13177,  0.13154,  0.13131,  0.13105/
      DATA (PSI(I,6),I=073,076)/  0.13079,  0.13051,  0.13020,  0.12989/
      DATA (PSI(I,6),I=077,080)/  0.12955,  0.12917,  0.12878,  0.12836/
      DATA (PSI(I,6),I=081,084)/  0.12792,  0.12747,  0.12698,  0.12648/
      DATA (PSI(I,6),I=085,088)/  0.12595,  0.12540,  0.12482,  0.12423/
      DATA (PSI(I,6),I=089,092)/  0.12361,  0.12295,  0.12228,  0.12158/
      DATA (PSI(I,6),I=093,096)/  0.12085,  0.12009,  0.11932,  0.11851/
      DATA (PSI(I,6),I=097,100)/  0.11768,  0.11683,  0.11596,  0.11507/
      DATA (PSI(I,6),I=101,104)/  0.11416,  0.11322,  0.11227,  0.11129/
      DATA (PSI(I,6),I=105,108)/  0.11030,  0.10928,  0.10825,  0.10720/
      DATA (PSI(I,6),I=109,112)/  0.10614,  0.10505,  0.10395,  0.10284/
      DATA (PSI(I,6),I=113,116)/  0.10171,  0.10057,  0.09941,  0.09825/
      DATA (PSI(I,6),I=117,120)/  0.09706,  0.09586,  0.09466,  0.09344/
      DATA (PSI(I,6),I=121,124)/  0.09221,  0.09096,  0.08972,  0.08845/
      DATA (PSI(I,6),I=125,128)/  0.08718,  0.08590,  0.08462,  0.08332/
      DATA (PSI(I,6),I=129,132)/  0.08202,  0.08071,  0.07941,  0.07810/
      DATA (PSI(I,6),I=133,136)/  0.07679,  0.07548,  0.07417,  0.07288/
      DATA (PSI(I,6),I=137,140)/  0.07158,  0.07029,  0.06902,  0.06775/
      DATA (PSI(I,6),I=141,144)/  0.06650,  0.06525,  0.06402,  0.06278/
      DATA (PSI(I,6),I=145,148)/  0.06156,  0.06035,  0.05914,  0.05794/
      DATA (PSI(I,6),I=149,152)/  0.05675,  0.05558,  0.05441,  0.05325/
      DATA (PSI(I,6),I=153,156)/  0.05210,  0.05096,  0.04983,  0.04872/
      DATA (PSI(I,6),I=157,160)/  0.04761,  0.04650,  0.04539,  0.04428/
      DATA (PSI(I,6),I=161,164)/  0.04315,  0.04203,  0.04089,  0.03973/
      DATA (PSI(I,6),I=165,168)/  0.03857,  0.03741,  0.03625,  0.03511/
      DATA (PSI(I,6),I=169,172)/  0.03399,  0.03291,  0.03186,  0.03086/
      DATA (PSI(I,6),I=173,176)/  0.02991,  0.02902,  0.02820,  0.02745/
      DATA (PSI(I,6),I=177,180)/  0.02677,  0.02615,  0.02559,  0.02509/
      DATA (PSI(I,6),I=181,184)/  0.02464,  0.02425,  0.02390,  0.02360/
      DATA (PSI(I,6),I=185,188)/  0.02333,  0.02311,  0.02293,  0.02277/
      DATA (PSI(I,6),I=189,192)/  0.02265,  0.02256,  0.02248,  0.02244/
      DATA (PSI(I,6),I=193,196)/  0.02240,  0.02238,  0.02238,  0.02238/
      DATA (PSI(I,6),I=197,200)/  0.02239,  0.02241,  0.02242,  0.02242/
      DATA  PSI(201,6)         /  0.02243  /
************************************************************************
      DATA (PSI(I,7),I=001,004)/  0.15365,  0.15354,  0.15318,  0.15263/
      DATA (PSI(I,7),I=005,008)/  0.15188,  0.15098,  0.14993,  0.14876/
      DATA (PSI(I,7),I=009,012)/  0.14748,  0.14614,  0.14473,  0.14330/
      DATA (PSI(I,7),I=013,016)/  0.14190,  0.14057,  0.13933,  0.13819/
      DATA (PSI(I,7),I=017,020)/  0.13717,  0.13626,  0.13544,  0.13472/
      DATA (PSI(I,7),I=021,024)/  0.13407,  0.13349,  0.13296,  0.13249/
      DATA (PSI(I,7),I=025,028)/  0.13208,  0.13170,  0.13137,  0.13107/
      DATA (PSI(I,7),I=029,032)/  0.13081,  0.13059,  0.13038,  0.13019/
      DATA (PSI(I,7),I=033,036)/  0.13004,  0.12990,  0.12978,  0.12969/
      DATA (PSI(I,7),I=037,040)/  0.12962,  0.12956,  0.12953,  0.12951/
      DATA (PSI(I,7),I=041,044)/  0.12949,  0.12949,  0.12949,  0.12948/
      DATA (PSI(I,7),I=045,048)/  0.12947,  0.12947,  0.12946,  0.12945/
      DATA (PSI(I,7),I=049,052)/  0.12944,  0.12943,  0.12942,  0.12941/
      DATA (PSI(I,7),I=053,056)/  0.12940,  0.12939,  0.12938,  0.12937/
      DATA (PSI(I,7),I=057,060)/  0.12936,  0.12934,  0.12932,  0.12929/
      DATA (PSI(I,7),I=061,064)/  0.12925,  0.12921,  0.12915,  0.12909/
      DATA (PSI(I,7),I=065,068)/  0.12902,  0.12894,  0.12885,  0.12876/
      DATA (PSI(I,7),I=069,072)/  0.12865,  0.12853,  0.12841,  0.12827/
      DATA (PSI(I,7),I=073,076)/  0.12812,  0.12797,  0.12781,  0.12762/
      DATA (PSI(I,7),I=077,080)/  0.12743,  0.12723,  0.12701,  0.12677/
      DATA (PSI(I,7),I=081,084)/  0.12652,  0.12625,  0.12596,  0.12567/
      DATA (PSI(I,7),I=085,088)/  0.12535,  0.12500,  0.12464,  0.12424/
      DATA (PSI(I,7),I=089,092)/  0.12380,  0.12333,  0.12281,  0.12224/
      DATA (PSI(I,7),I=093,096)/  0.12164,  0.12099,  0.12030,  0.11958/
      DATA (PSI(I,7),I=097,100)/  0.11883,  0.11805,  0.11724,  0.11641/
      DATA (PSI(I,7),I=101,104)/  0.11554,  0.11466,  0.11375,  0.11282/
      DATA (PSI(I,7),I=105,108)/  0.11186,  0.11088,  0.10988,  0.10885/
      DATA (PSI(I,7),I=109,112)/  0.10781,  0.10675,  0.10568,  0.10459/
      DATA (PSI(I,7),I=113,116)/  0.10349,  0.10237,  0.10124,  0.10009/
      DATA (PSI(I,7),I=117,120)/  0.09893,  0.09776,  0.09657,  0.09537/
      DATA (PSI(I,7),I=121,124)/  0.09416,  0.09294,  0.09170,  0.09045/
      DATA (PSI(I,7),I=125,128)/  0.08919,  0.08793,  0.08664,  0.08537/
      DATA (PSI(I,7),I=129,132)/  0.08407,  0.08277,  0.08147,  0.08017/
      DATA (PSI(I,7),I=133,136)/  0.07886,  0.07755,  0.07625,  0.07495/
      DATA (PSI(I,7),I=137,140)/  0.07365,  0.07235,  0.07105,  0.06976/
      DATA (PSI(I,7),I=141,144)/  0.06848,  0.06720,  0.06592,  0.06466/
      DATA (PSI(I,7),I=145,148)/  0.06340,  0.06215,  0.06091,  0.05967/
      DATA (PSI(I,7),I=149,152)/  0.05846,  0.05724,  0.05604,  0.05485/
      DATA (PSI(I,7),I=153,156)/  0.05368,  0.05250,  0.05135,  0.05020/
      DATA (PSI(I,7),I=157,160)/  0.04906,  0.04792,  0.04678,  0.04564/
      DATA (PSI(I,7),I=161,164)/  0.04450,  0.04333,  0.04216,  0.04098/
      DATA (PSI(I,7),I=165,168)/  0.03978,  0.03859,  0.03740,  0.03623/
      DATA (PSI(I,7),I=169,172)/  0.03508,  0.03396,  0.03288,  0.03184/
      DATA (PSI(I,7),I=173,176)/  0.03085,  0.02992,  0.02906,  0.02827/
      DATA (PSI(I,7),I=177,180)/  0.02754,  0.02688,  0.02628,  0.02573/
      DATA (PSI(I,7),I=181,184)/  0.02524,  0.02480,  0.02440,  0.02406/
      DATA (PSI(I,7),I=185,188)/  0.02375,  0.02348,  0.02326,  0.02306/
      DATA (PSI(I,7),I=189,192)/  0.02290,  0.02277,  0.02266,  0.02259/
      DATA (PSI(I,7),I=193,196)/  0.02252,  0.02247,  0.02245,  0.02242/
      DATA (PSI(I,7),I=197,200)/  0.02242,  0.02242,  0.02242,  0.02242/
      DATA  PSI(201,7)         /  0.02243  /
************************************************************************
      DATA (PSI(I,8),I=001,004)/  0.14761,  0.14746,  0.14701,  0.14632/
      DATA (PSI(I,8),I=005,008)/  0.14542,  0.14435,  0.14314,  0.14185/
      DATA (PSI(I,8),I=009,012)/  0.14052,  0.13916,  0.13785,  0.13662/
      DATA (PSI(I,8),I=013,016)/  0.13554,  0.13460,  0.13376,  0.13296/
      DATA (PSI(I,8),I=017,020)/  0.13216,  0.13136,  0.13056,  0.12974/
      DATA (PSI(I,8),I=021,024)/  0.12892,  0.12808,  0.12722,  0.12638/
      DATA (PSI(I,8),I=025,028)/  0.12555,  0.12476,  0.12406,  0.12342/
      DATA (PSI(I,8),I=029,032)/  0.12288,  0.12247,  0.12219,  0.12204/
      DATA (PSI(I,8),I=033,036)/  0.12199,  0.12201,  0.12210,  0.12222/
      DATA (PSI(I,8),I=037,040)/  0.12235,  0.12246,  0.12258,  0.12268/
      DATA (PSI(I,8),I=041,044)/  0.12279,  0.12289,  0.12300,  0.12310/
      DATA (PSI(I,8),I=045,048)/  0.12321,  0.12331,  0.12343,  0.12354/
      DATA (PSI(I,8),I=049,052)/  0.12365,  0.12376,  0.12387,  0.12397/
      DATA (PSI(I,8),I=053,056)/  0.12407,  0.12417,  0.12426,  0.12435/
      DATA (PSI(I,8),I=057,060)/  0.12443,  0.12451,  0.12459,  0.12466/
      DATA (PSI(I,8),I=061,064)/  0.12472,  0.12478,  0.12484,  0.12488/
      DATA (PSI(I,8),I=065,068)/  0.12492,  0.12496,  0.12499,  0.12501/
      DATA (PSI(I,8),I=069,072)/  0.12502,  0.12503,  0.12502,  0.12501/
      DATA (PSI(I,8),I=073,076)/  0.12499,  0.12495,  0.12491,  0.12487/
      DATA (PSI(I,8),I=077,080)/  0.12481,  0.12474,  0.12466,  0.12457/
      DATA (PSI(I,8),I=081,084)/  0.12448,  0.12436,  0.12424,  0.12410/
      DATA (PSI(I,8),I=085,088)/  0.12394,  0.12377,  0.12358,  0.12338/
      DATA (PSI(I,8),I=089,092)/  0.12316,  0.12292,  0.12266,  0.12237/
      DATA (PSI(I,8),I=093,096)/  0.12206,  0.12174,  0.12137,  0.12099/
      DATA (PSI(I,8),I=097,100)/  0.12058,  0.12013,  0.11965,  0.11914/
      DATA (PSI(I,8),I=101,104)/  0.11859,  0.11801,  0.11740,  0.11675/
      DATA (PSI(I,8),I=105,108)/  0.11607,  0.11534,  0.11459,  0.11379/
      DATA (PSI(I,8),I=109,112)/  0.11297,  0.11211,  0.11122,  0.11031/
      DATA (PSI(I,8),I=113,116)/  0.10937,  0.10840,  0.10741,  0.10639/
      DATA (PSI(I,8),I=117,120)/  0.10536,  0.10431,  0.10324,  0.10217/
      DATA (PSI(I,8),I=121,124)/  0.10107,  0.09995,  0.09881,  0.09766/
      DATA (PSI(I,8),I=125,128)/  0.09650,  0.09532,  0.09412,  0.09292/
      DATA (PSI(I,8),I=129,132)/  0.09170,  0.09046,  0.08921,  0.08796/
      DATA (PSI(I,8),I=133,136)/  0.08668,  0.08541,  0.08412,  0.08282/
      DATA (PSI(I,8),I=137,140)/  0.08151,  0.08020,  0.07889,  0.07755/
      DATA (PSI(I,8),I=141,144)/  0.07622,  0.07489,  0.07354,  0.07220/
      DATA (PSI(I,8),I=145,148)/  0.07084,  0.06949,  0.06813,  0.06678/
      DATA (PSI(I,8),I=149,152)/  0.06543,  0.06408,  0.06275,  0.06141/
      DATA (PSI(I,8),I=153,156)/  0.06009,  0.05879,  0.05749,  0.05621/
      DATA (PSI(I,8),I=157,160)/  0.05494,  0.05367,  0.05240,  0.05113/
      DATA (PSI(I,8),I=161,164)/  0.04985,  0.04857,  0.04727,  0.04597/
      DATA (PSI(I,8),I=165,168)/  0.04465,  0.04333,  0.04202,  0.04072/
      DATA (PSI(I,8),I=169,172)/  0.03943,  0.03818,  0.03695,  0.03577/
      DATA (PSI(I,8),I=173,176)/  0.03463,  0.03355,  0.03252,  0.03156/
      DATA (PSI(I,8),I=177,180)/  0.03067,  0.02982,  0.02904,  0.02831/
      DATA (PSI(I,8),I=181,184)/  0.02763,  0.02702,  0.02644,  0.02592/
      DATA (PSI(I,8),I=185,188)/  0.02544,  0.02500,  0.02461,  0.02426/
      DATA (PSI(I,8),I=189,192)/  0.02394,  0.02365,  0.02341,  0.02320/
      DATA (PSI(I,8),I=193,196)/  0.02302,  0.02286,  0.02274,  0.02263/
      DATA (PSI(I,8),I=197,200)/  0.02255,  0.02250,  0.02245,  0.02243/
      DATA  PSI(201,8)         /  0.02242  /
************************************************************************
* 
*  ROUTINE -BDTA6S- COMPLETE 
* 
      END 

CCCCCCCCCC AUTHOR; D.W. SPROLES, CSC, 13 AUG 90, 804-865-1725 CCCCCCCCCC
C 
C 
C>                           BLKDTA 
C 
C 
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C  LANGUAGE: FORTRAN 77
C  RESTRICTIONS, ASSUMPTIONS:
C          NONE 
C  NON-ANSI CONSTRUCTS:
C          NONE
C  CHANGES:
C          iii-ddmmmyy-xxxxxxxx xxxx xx xxxx.  
************************************************************************
*
*  BLOCK DATA PROGRAM SPECIFICATIONS.
*
************************************************************************
      BLOCK DATA BLKDTA 
* 
*  SPECIFICATIONS 
* 
      INCLUDE 'advics.h'
      INCLUDE 'chstg.h'
      COMMON /CODES/ IDT, IFALSE, IOS, ITRUE, MEX, MPR
      INCLUDE 'lists.h'
      COMMON /OPVAL/ IOP, IOPCR, IOPE, IOPQ, IOPQM, IOPSL, NOP
      INCLUDE 'numfil.h'
* 
*  INITIALIZATIONS
* 
************************************************************************
      DATA (ANS(I), I=1,10)/ '4', '9', 'IJG', ' 1',
     +                       '3', ' ', '/EX', '?', 
     +                       'E', 'Q' /
************************************************************************
      DATA IFALSE/ 0 /
      DATA ITRUE / 1 /
************************************************************************
      DATA IOPCR/ -1 /
      DATA IOPE / -4 /
      DATA IOPQ / -5 /
      DATA IOPQM/ -3 /
      DATA IOPSL/ -2 /
      DATA NOP  /  5 /
************************************************************************
*  RESERVE FILE UNIT(S); 9
* 
      DATA IUA / 3 /
      DATA IUD / 1 /
      DATA IUR / 2 /
************************************************************************
      DATA MESSG1(01)/ '3' /
      DATA MESSG1(02)/ 'ENTERED WAS THE FOURTH OPTION LISTED, THE' /
      DATA MESSG1(03)/ 'PROGRAM WILL TAKE THE ACTION REQUESTED BY' /
      DATA MESSG1(04)/ 'THAT SELECTION' /
      DATA MESSG1(05)/ '3' /
      DATA MESSG1(06)/ 'ENTERED WAS THREE INCORRECT ENTRIES OF' /
      DATA MESSG1(07)/ 'VARIOUS FORM TO SHOW THE PROGRAM''S REACTION' /
      DATA MESSG1(08)/ 'FOLLOWED BY A CORRECT ENTRY THAT IS ACCEPTED' /
      DATA MESSG1(09)/ '3' /
      DATA MESSG1(10)/ 'ENTERED WAS A CARRIAGE RETURN CAUSING VALUE' /
      DATA MESSG1(11)/ 'OF DEFAULT WHEN ONE EXIST BE ASSIGNED OR AS' /
      DATA MESSG1(12)/ 'FOR THIS CASE CLEAR SCREEN AND REPEAT MENU'/
      DATA MESSG1(13)/ '3' /
      DATA MESSG1(14)/ 'ENTERED WAS A REQUEST FOR PROGRAM RESPONSE' /
      DATA MESSG1(15)/ 'CAUSING RESPONSE MENU DISPLAY OR AS FOR' /
      DATA MESSG1(16)/ 'THIS CASE RESPONSE SPECIFIED IS PERFORMED' /
      DATA MESSG1(17)/ '3' /
      DATA MESSG1(18)/ 'ENTERED WAS A REQUEST FOR EXPLANATION ABOUT' /
      DATA MESSG1(19)/ 'PRESENT INQUIRY DISPLAY, REPORTED WILL BE' /
      DATA MESSG1(20)/ 'INFORMATION ABOUT EXPECTED USER RESPONSE' /
      DATA MESSG1(21)/ '3' /
      DATA MESSG1(22)/ 'ENTERED WAS A REQUEST FOR PROGRAM TO EXIT' /
      DATA MESSG1(23)/ 'THE INQUIRY i.e., TERMINATE SELECTION FROM' /
      DATA MESSG1(24)/ 'PRESENT MENU, THIS EXAMPLE IGNORES REQUEST' /
      DATA MESSG1(25)/ '3' /
      DATA MESSG1(26)/ 'ENTERED WAS A REQUEST FOR PROGRAM TO QUIT' /
      DATA MESSG1(27)/ 'i.e., TERMINATE ALL FURTHER PROCESSING BY' /
      DATA MESSG1(28)/ 'THE PROGRAM, THIS EXAMPLE IGNORES REQUEST' /
************************************************************************
      DATA ADVIC1(1)/ '3' /
      DATA ADVIC1(2)/ 'ENTER SELECTION ASSOCIATED WITH DESCRIPTION OF' /
      DATA ADVIC1(3)/ 'COMPUTER TERMINAL PRESENTLY BEING USED TO' /
      DATA ADVIC1(4)/ 'EXCUTE THIS PROGRAM OR A PROGRAM CONTROL <_>' /
      DATA CUES1(1)/ 'DEVICE' /
      DATA LIST1(01)/ 'ANSIT - ANSI TERMINAL OR EMULATOR' /
      DATA LIST1(02)/ 'IBMPC - IBM PERSONAL COMPUTER OR COMPATIBLE' /
      DATA LIST1(03)/ 'T4107 - TEKTRONIX 4107' / 
      DATA LIST1(04)/ 'SUNWS - SUN MICROSYSTEMS WORKSTATION CONSOLE' /
      DATA LIST1(05)/ 'VT_50 - DEC VT TERMINAL 50' / 
      DATA LIST1(06)/ 'VT100 - DEC VT TERMINAL 100' / 
      DATA LIST1(07)/ 'VT200 - DEC VT TERMINAL 200' / 
      DATA LIST1(08)/ 'VT240 - DEC VT TERMINAL 240 WITH REGIS' / 
      DATA LIST1(09)/ 'VTERM - IBM PERSONAL COMPUTER VTERM PACKAGE' / 
      DATA LIST1(10)/ 'XTERM - TERMINAL EMULATOR FOR X' / 
      DATA LIST1(11)/ 'NONE OF THE APPLICABLE DEVICES - NO-OP' / 
************************************************************************
      DATA ADVIC2(1)/ '4' /
      DATA ADVIC2(2)/ 'ENTER SELECTION ASSOCIATED WITH THE THICKNESS' /
      DATA ADVIC2(3)/ 'DISTRIBUTION FAMILY DESIGNATION FOR WHICH' /
      DATA ADVIC2(4)/ 'GENERATION OF AIRFOIL ORDINATES IS DESIRED' /
      DATA ADVIC2(5)/ 'OR A PROGRAM CONTROL <_>' /
      DATA CUES1(2)/ 'AIRFOIL SECTION' /
      DATA LIST2(01)/ 'NACA 4-DIGIT SERIES' / 
      DATA LIST2(02)/ 'NACA MODIFIED 4-DIGIT SERIES' / 
      DATA LIST2(03)/ 'NACA 6-SERIES' / 
      DATA LIST2(04)/ 'NACA 6A-SERIES' / 
      DATA LIST2(05)/ 'NACA 16-SERIES' / 
      DATA LIST2(06)/ 'NACA 5-DIGIT SERIES' / 
      DATA LIST2(07)/ 'NACA MODIFIED 5-DIGIT SERIES' / 
************************************************************************
      DATA ADVIC3(1)/ '3' /
      DATA ADVIC3(2)/ 'ENTER SELECTION ASSOCIATED WITH THE MEAN LINE' /
      DATA ADVIC3(3)/ 'DESIGNATION FOR WHICH CAMBERING OF AIRFOIL' /
      DATA ADVIC3(4)/ 'SECTION IS DESIRED OR A PROGRAM CONTROL <_>' /
      DATA CUES1(3)/ 'MEAN LINE' /
      DATA LIST3(01)/ 'NACA 2-DIGIT' / 
      DATA LIST3(02)/ 'NACA 3-DIGIT' / 
      DATA LIST3(03)/ 'NACA 3-DIGIT REFLEX' / 
      DATA LIST3(04)/ 'NACA 6-SERIES' / 
      DATA LIST3(05)/ 'NACA 6A-SERIES' / 
************************************************************************
      DATA ADVIC4(1)/ '2' /
      DATA ADVIC4(2)/ 'ENTER <Y> FOR YES, <N> FOR NO OR' /
      DATA ADVIC4(3)/ 'A VALID PROGRAM CONTROL CHARACTER <_>' /
      DATA CUES1(4)/ 'AIRFOIL CAMBER' /
      DATA LIST4(01)/ 'CAMBER AIRFOIL SECTION' / 
      DATA LIST4(02)/ 'NO CAMBER DESIRED' / 
************************************************************************
      DATA ADVIC5(1)/ '0' /
      DATA CUES1(5)/ 'SYSTEM PROMPT' /
      DATA LIST5(01)/ '/ED =*EDIT' /
      DATA LIST5(02)/ '/EX =EXAMPLE' / 
      DATA LIST5(03)/ '/RE =*REPEAT' / 
      DATA LIST5(04)/ '/RS =RESTART' / 
      DATA LIST5(05)/ '/VW =*VIEW' / 
************************************************************************
      DATA ADVIC6(1)/ '2' /
      DATA ADVIC6(2)/ 'ENTER <T> FOR TRUE, <F> FOR FALSE OR' /
      DATA ADVIC6(3)/ 'A VALID PROGRAM CONTROL CHARACTER <_>' /
      DATA CUES1(6)/ 'USER IS EXPERIENCED WITH AIRFOLS' /
      DATA LIST6(01)/ 'NO MENU TUTORIAL REQUIRED' /
      DATA LIST6(02)/ 'SHOW TUTORIAL ON MENU USE' /
************************************************************************
      DATA ADVIC7(1)/ '2' /
      DATA ADVIC7(2)/ 'CHOOSE 1 OF THE 4 LISTED OPTIONS OR' /
      DATA ADVIC7(3)/ 'A VALID PROGRAM CONTROL CHARACTER <_>' /
      DATA CUES1(7)/ 'EXAMPLE' /
      DATA LIST7(01)/ 'CHOOSE ONE OF THE PROGRAM CONTROLS' /
      DATA LIST7(02)/ 'CHOOSE ONE OF THE LISTED OPTIONS' /
      DATA LIST7(03)/ 'ANYTHING ELSE, INCORRECT ENTRY' /
      DATA LIST7(04)/ 'AS AN EXAMPLE, LOOK AT ALL' /
************************************************************************
      DATA ADVIC8(1)/ '2' /
      DATA ADVIC8(2)/ 'ENTER <Y> FOR YES, <N> FOR NO OR' /
      DATA ADVIC8(3)/ 'A VALID PROGRAM CONTROL CHARACTER <_>' /
      DATA CUES1(8)/ 'DESIRE ORDINATES FOR STANDARD NACA AIRFOIL' /
      DATA LIST8(01)/ 'STANDARD NACA AIRFOIL TO BE DESCRIBED' / 
      DATA LIST8(02)/ 'NONSTANDARD NACA AIRFOIL TO BE DESCRIBED' / 
************************************************************************
      DATA ADVIC9(1)/ '3' /
      DATA ADVIC9(2)/ 'ENTER SELECTION ASSOCIATED WITH THE 3-DIGIT' /
      DATA ADVIC9(3)/ 'MEAN LINE DESIGNATION REPRESENTING THE DESIRED' /
      DATA ADVIC9(4)/ 'VALUES OF m, r AND k1 OR A PROGRAM CONTROL <_>' /
      DATA CUES1(9)/ '3-DIGIT MEAN LINE DESIGNATION' /
      DATA LIST9(01)/ '210    (m=.05  r=.0580  k1=361.400)' / 
      DATA LIST9(02)/ '220    (m=.10  r=.1260  k1= 51.640)' / 
      DATA LIST9(03)/ '230    (m=.15  r=.2025  k1= 15.957)' / 
      DATA LIST9(04)/ '240    (m=.20  r=.2900  k2=  6.643)' / 
      DATA LIST9(05)/ '250    (m=.25  r=.3910  k2=  3.230)' / 
************************************************************************
      DATA ADVC10(1)/ '4' /
      DATA ADVC10(2)/ 'ENTER SELECTION ASSOCIATED WITH THE 3-DIGIT' /
      DATA ADVC10(3)/ 'REFLEX MEAN LINE DESIGNATION REPRESENTING THE' /
      DATA ADVC10(4)/ 'DESIRED VALUES OF m, r, k1 AND k2/k1 OR A' /
      DATA ADVC10(5)/ 'PROGRAM CONTROL <_>' /
      DATA CUES1(10)/ '3-DIGIT REFLEX MEAN LINE DESIGNATION' /
      DATA LIST10(1)/'221    (m=.10  r=.130  k1=51.990  k2/k1=.000764)'/ 
      DATA LIST10(2)/'231    (m=.15  r=.217  k1=15.793  k2/k1=.006770)'/ 
      DATA LIST10(3)/'241    (m=.20  r=.318  k1= 6.520  k2/k1=.030300)'/ 
      DATA LIST10(4)/'251    (m=.25  r=.441  k1= 3.191  k2/k1=.135500)'/ 
************************************************************************
      DATA ADVC11(1)/ '2' /
      DATA ADVC11(2)/ 'ENTER <Y> FOR YES, <N> FOR NO OR' /
      DATA ADVC11(3)/ 'A VALID PROGRAM CONTROL CHARACTER <_>' /
      DATA CUES1(11)/ 'DESIRE TO DESCRIBE ADDITIONAL AIRFOILS' /
      DATA LIST11(01)/ 'ADDITIONAL AIRFOIL TO BE DESCRIBED' / 
      DATA LIST11(02)/ 'COMPLETED DESIRED AIRFOIL SPECIFICATIONS' / 
************************************************************************
      DATA ADVC12(1)/ '4' /
      DATA ADVC12(2)/ 'ENTER SELECTION ASSOCIATED WITH THE 6-SERIES' /
      DATA ADVC12(3)/ 'AIRFOIL SECTION DESIGNATION REPRESENTING THE' /
      DATA ADVC12(4)/ 'SPECIFIC THICKNESS DISTRIBUTION OF THE FAMILY' /
      DATA ADVC12(5)/ 'DESIRED OR A PROGRAM CONTROL <_>' /
      DATA CUES1(12)/ '6-SERIES AIRFOIL DESIGNATION' /
      DATA LIST12(1)/'63'/ 
      DATA LIST12(2)/'64'/ 
      DATA LIST12(3)/'65'/ 
      DATA LIST12(4)/'66'/ 
      DATA LIST12(5)/'67'/ 
************************************************************************
      DATA ADVC13(1)/ '4' /
      DATA ADVC13(2)/ 'ENTER SELECTION ASSOCIATED WITH THE 6A-SERIES' /
      DATA ADVC13(3)/ 'AIRFOIL SECTION DESIGNATION REPRESENTING THE' /
      DATA ADVC13(4)/ 'SPECIFIC THICKNESS DISTRIBUTION OF THE FAMILY' /
      DATA ADVC13(5)/ 'DESIRED OR A PROGRAM CONTROL <_>' /
      DATA CUES1(13)/ '6A-SERIES AIRFOIL DESIGNATION' /
      DATA LIST13(1)/'63A'/ 
      DATA LIST13(2)/'64A'/ 
      DATA LIST13(3)/'65A'/ 
************************************************************************
      DATA ADVC14(1)/ '2' /
      DATA ADVC14(2)/ 'ENTER THE THICKNESS TO CHORD RATIO;' /
      DATA ADVC14(3)/ 'i.e.,  .12, .13, . . .' /
      DATA CUES2(1)/ 'THICKNESS/CHORD RATIO (REAL)' /
*    
      DATA ADVC14(4)/ '2' /
      DATA ADVC14(5)/ 'ENTER BASIC CHORDWISE INCREMENT IN X/C FOR' /
      DATA ADVC14(6)/ 'COMPUTING ORDINATES; USUALLY ASSIGN TO 0.01' /
      DATA CUES2(2)/ 'CHORDWISE INCREMENT IN X/C (REAL)' /
*    
      DATA ADVC14(7)/ '2' /
      DATA ADVC14(8)/ 'ENTER MODEL CHORD USED FOR LISTING ORDINATES' /
      DATA ADVC14(9)/ 'IN DIMENSIONAL UNITS' /
      DATA CUES2(3)/ 'MODEL CHORD IN DIMENSIONAL UNITS (REAL)' /
*    
      DATA ADVC14(10)/ '4' /
      DATA ADVC14(11)/ 'ENTER THE LEADING EDGE RADIUS TO CHORD RATIO;' /
      DATA ADVC14(12)/ 'i.e.,  .0003, .004, .06, . . .' /
      DATA ADVC14(13)/ 'OR THE LEADING EDGE INDEX;' /
      DATA ADVC14(14)/ 'i.e.,  0, 6, 9, . . .' /
      DATA CUES2(4)/ 'LEADING EDGE INDEX or RAD/CHD RATIO (INTorREAL)' /
*    
      DATA ADVC14(15)/ '3' /
      DATA ADVC14(16)/ 'ENTER RATIO OF LOCATION OF MAXIMUM THICKNESS' /
      DATA ADVC14(17)/ 'TO CHORD FROM THE LEADING EDGE' /
      DATA ADVC14(18)/ 'i.e.,  .40, .30, . . .' /
      DATA CUES2(5)/'MAX THICKNESS LOCATION TO CHORD RATIO (REAL)'/
*    
      DATA ADVC14(19)/ '2' /
      DATA ADVC14(20)/ 'ENTER TRAILING EDGE SLOPE; APPROXIMATE VALUE' /
      DATA ADVC14(21)/ 'WILL BE USED IF <cr> OR 0.0 IS INPUT' /
      DATA CUES2(6)/ 'TRAILING EDGE SLOPE (REAL=XXXX.XXXXXX)' /
*    
      DATA ADVC14(22)/ '2' /
      DATA ADVC14(23)/ 'ENTER MAXIMUM CAMBER ORDINATE TO CHORD RATIO,' /
      DATA ADVC14(24)/ 'P OR K1; i.e.,  0.04, . . .' /
      DATA CUES2(7)/ 'MAXIMUM CAMBER ORDINATE/CHORD RATIO (REAL)' /
*    
      DATA ADVC14(25)/ '3' /
      DATA ADVC14(26)/ 'ENTER THE RATIO OF LONGITUDINAL LOCATION OF' /
      DATA ADVC14(27)/ 'MAXIMUM CAMBER POSITION TO CHORD, M OR R;' /
      DATA ADVC14(28)/ 'i.e.,  .40, .20, . . .' /
      DATA CUES2(8)/ 'MAX CAMBER LOCATION TO CHORD RATIO (REAL)' /
*    
      DATA ADVC14(29)/ '1' /
      DATA ADVC14(30)/ 'ENTER NUMBER OF CAMBER LINES TO BE SUMMED' /
      DATA CUES2(9)/ 'NUMBER OF CAMBER LINES, MAX OF 10 (INT= 1)' /
*    
      DATA ADVC14(31)/ '2' /
      DATA ADVC14(32)/ 'ENTER THE DESIGN LIFT COEFFICIENT;' /
      DATA ADVC14(33)/ 'i.e.,  0.20, . . .' /
      DATA CUES2(10)/ 'DESIGN LIFT COEFFICIENT (REAL)' /
*    
      DATA ADVC14(34)/ '2' /
      DATA ADVC14(35)/ 'ENTER THE MEAN LINE CHORDWISE LOADING;' /
      DATA ADVC14(36)/ 'USE 0.80 FOR 6A-SERIES' /
      DATA CUES2(11)/ 'MEAN LINE CHORDWISE LOADING (REAL)' /
*    
      DATA ADVC14(37)/ '2' /
      DATA ADVC14(38)/ 'ENTER A TITLE TO DESCRIBE THE AIRFOIL;' /
      DATA ADVC14(39)/ 'i.e.,  NACA 4412, NACA0012-45 (16-012), . . .' /
      DATA CUES2(12)/ 'AIRFOIL TITLE (CHAR*60)' /
*    
      DATA ADVC14(40)/ '4' /
      DATA ADVC14(41)/ 'ENTER A PATH (OPTIONAL) AND A FILE PREFIX FOR' /
      DATA ADVC14(42)/ 'THE REPORT AND DATA OUTPUTS SUFFIXED .rpt AND' /
      DATA ADVC14(43)/ '.dta, RESPECTIVELY; FILE NAME LENGTH AND' /
      DATA ADVC14(44)/ 'PATH FORMAT ARE OPERATING SYSTEM DEPENDENT;' /
      DATA ADVC14(45)/ 'i.e.,  C:\DATA\M4D, /bob/sect/NACA0012, . . .' /
      DATA CUES2(13)/ '[PATH] & FILE PREFIX FOR .rpt & .dta (CHAR*60)' /
************************************************************************
* 
*  ROUTINE -BLKDTA- COMPLETE 
* 
      END 

