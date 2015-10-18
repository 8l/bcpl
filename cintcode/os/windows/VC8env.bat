echo "Setting the BCPL environment variables"

cd \distribution\BCPL\cintcode
set BCPLROOT=/distribution/BCPL/cintcode
set BCPLPATH=%BCPLROOT%/cin
set BCPLHDRS=%BCPLROOT%/g
set BCPLSCRIPTS=%BCPLROOT%/s
set BCPL64ROOT=/distribution/BCPL/cintcode
set BCPL64PATH=%BCPL64ROOT%/cin64
set BCPL64HDRS=%BCPL64ROOT%/g
set BCPL64SCRIPTS=%BCPL64ROOT%/s
set PATH=E:\distribution\BCPL\cintcode\bin;%PATH%

set MUSHDRS=/distribution/Musprogs/g

echo "Copying some key system files"

copy enderlit\syslib cin\syscin
copy enderlit\boot cin\syscin
copy enderlit\blib cin\syscin
copy enderlit\dlib cin\syscin
copy enderlit\cli cin\syscin
copy enderlit\bcpl cin
copy enderlit\c cin
copy enderlit\echo cin
copy enderlit\logout cin
copy enderlit\b .
copy enderlit\bc .
copy enderlit\bs .
copy enderlit\b64 .
copy enderlit\bc64 .
copy enderlit\bs64 .
copy enderlit\bcb .
copy enderlit\bcl .
copy enderlit\bsb .
copy enderlit\bsl .
copy enderlit\bcb64 .
copy enderlit\bcl64 .
copy enderlit\bsb64 .
copy enderlit\bsl64 .

echo "Calling vcvars32 to setup Visual Studio"

"C:\Program Files\Microsoft Visual Studio 8\VC\bin\vcvars32.bat"
rem "C:\Program Files\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
rem "C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\vcvars32.bat"
