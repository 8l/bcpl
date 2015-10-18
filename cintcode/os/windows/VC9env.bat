echo "Setting the BCPL environment variables"

cd \distribution\BCPL\cintcode
set BCPLROOT=/distribution/BCPL/cintcode
set BCPLPATH=%BCPLROOT%/cin
set BCPLHDRS=%BCPLROOT%/g
set BCPLSCRIPTS=%BCPLROOT%/s
set PATH=E:\distribution\BCPL\cintcode;%PATH%

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
copy enderlit\bcb .
copy enderlit\bcl .
copy enderlit\bsb .
copy enderlit\bsl .

echo "Calling vcvars32 to setup Visual Studio"

rem "C:\Program Files\Microsoft Visual Studio 8\VC\bin\vcvars32.bat"
"C:\Program Files\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
rem "C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\vcvars32.bat"
