/*
This program give a table of which calanders are equivalent, ie
which have 1 January on the same day and are or are not leap years.

Usage: calendars "start/n, end/n"

start and end are the first year and last years to consider.

Typical output is :-

Non-leap years:
1 Jan is Monday:     2001 2007 2018 2029 2035 2046 2057 2063 2074 2085 2091
1 Jan is Tuesday:    2002 2013 2019 2030 2041 2047 2058 2069 2075 2086 2097
1 Jan is Wednesday:  2003 2014 2025 2031 2042 2053 2059 2070 2081 2087 2098
1 Jan is Thursday:   2009 2015 2026 2037 2043 2054 2065 2071 2082 2093 2099
1 Jan is Friday:     2010 2021 2027 2038 2049 2055 2066 2077 2083 2094 2100
1 Jan is Saturday:   2005 2011 2022 2033 2039 2050 2061 2067 2078 2089 2095
1 Jan is Sunday:     2006 2017 2023 2034 2045 2051 2062 2073 2079 2090

Leap years:
1 Jan is Monday:     2024 2052 2080
1 Jan is Tuesday:    2008 2036 2064 2092
1 Jan is Wednesday:  2020 2048 2076
1 Jan is Thursday:   2004 2032 2060 2088
1 Jan is Friday:     2016 2044 2072
1 Jan is Saturday:   2000 2028 2056 2084
1 Jan is Sunday:     2012 2040 2068 2096

*/


SECTION "calendars"

GET "libhdr"

GLOBAL { startyear:ug; endyear; firstyear }

MANIFEST { mon=0; sun=6; jan=0; feb=1; dec=11 }

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("start/n,end/n", argv, 50) DO
  { writef("Bad arguments for calendar*n")
    RESULTIS 0
  }

  startyear := argv!0 -> !argv!0, 2000
  endyear   := argv!1 -> !argv!1, 2100

  IF startyear<0 | endyear>startyear+399 DO
  { writef("Bad year range %n to %n*n*n", startyear, endyear)
    RESULTIS 0
  }

  firstyear := 1973  // Chosen because 1 January is a Monday

  UNTIL firstyear >= startyear DO firstyear := firstyear+400
  UNTIL firstyear <= startyear DO firstyear := firstyear-400

//writef("firstyear=%n startyear=%n endyear=%n*n", firstyear, startyear, endyear)

  FOR i = 0 TO 1 DO
  { LET leap = i=1
    writef("*n%s years:*n", leap -> "Leap", "Non-leap")
    FOR day = mon TO sun DO
    { LET days = 0
      LET year = firstyear

      writef("1 Jan is %s", select(day, "Monday:    ",
                                        "Tuesday:   ",
                                        "Wednesday: ",
                                        "Thursday:  ",
                                        "Friday:    ",
                                        "Saturday:  ",
                                        "Sunday:    ")
             )
      WHILE year<=endyear DO
      { LET b = isleap(year)
        IF days MOD 7 = day & year>=startyear & b=leap DO writef(" %i4", year)
        days := days + 365
        IF b DO days := days + 1
        year := year+1
      }
      newline()
    }
  }

  RESULTIS 0
}

AND isleap(year) = year REM 400 = 0 -> TRUE,
                   year REM 100 = 0 -> FALSE,
                   year REM 4   = 0 -> TRUE,
                   FALSE

AND select(n, a0, a1, a2, a3, a4, a5, a6) = n!@a0


