(local { : base64 : assoc } (require :anoia))
(import-macros { : expect= : define-tests } :anoia.assert)

(local
 leap-seconds-list
 (let [tbl
       [
        ;; https://data.iana.org/time-zones/data/leap-seconds.list
        ;; comments are the _start_ of the day where the second was
        ;; added at the end of the previous day
        [2272060800      10]   ;    1 jan 1972 ; baseline, not a leap second
        [2287785600      11]   ;    1 jul 1972
        [2303683200      12]   ;    1 jan 1973
        [2335219200      13]   ;    1 jan 1974
        [2366755200      14]   ;    1 Jan 1975
        [2398291200      15]   ;    1 Jan 1976
        [2429913600      16]   ;    1 Jan 1977
        [2461449600      17]   ;    1 Jan 1978
        [2492985600      18]   ;    1 Jan 1979
        [2524521600      19]   ;    1 Jan 1980
        [2571782400      20]   ;    1 Jul 1981
        [2603318400      21]   ;    1 Jul 1982
        [2634854400      22]   ;    1 Jul 1983
        [2698012800      23]   ;    1 Jul 1985
        [2776982400      24]   ;    1 Jan 1988
        [2840140800      25]   ;    1 Jan 1990
        [2871676800      26]   ;    1 Jan 1991
        [2918937600      27]   ;    1 Jul 1992
        [2950473600      28]   ;    1 Jul 1993
        [2982009600      29]   ;    1 Jul 1994
        [3029443200      30]   ;    1 Jan 1996
        [3076704000      31]   ;    1 Jul 1997
        [3124137600      32]   ;    1 Jan 1999
        [3345062400      33]   ;    1 Jan 2006
        [3439756800      34]   ;    1 Jan 2009
        [3550089600      35]   ;    1 Jul 2012
        [3644697600      36]   ;    1 Jul 2015
        [3692217600      37]   ;    1 Jan 2017
        ]]
   {
    :tai
    (icollect [_ [ts dtai] (ipairs tbl)]
      [(+ (- ts 2208988800) dtai) dtai])
    :unix
    (icollect [_ [ts dtai] (ipairs tbl)]
      [(- ts 2208988800) dtai])
    }))


(fn leap-seconds [timestamp list]
  (accumulate [secs 10
               _ [epoch leap-seconds] (ipairs list)
               &until (> epoch timestamp)]
    leap-seconds))

(fn leap-seconds-tai [tai] (leap-seconds tai leap-seconds-list.tai))
(fn leap-seconds-unix [unix] (leap-seconds unix leap-seconds-list.unix))

(define-tests :leap-seconds
  (expect= (leap-seconds-tai 104694412) 12)
  (expect= (leap-seconds-tai 23) 10)
  (expect= (leap-seconds-tai (+ 3692217600 60)) 37)
  (expect= (leap-seconds-tai (+ 10 773020829)) 29)
  (expect= (leap-seconds-tai 362793520) 19))

(fn from-timestamp [str]
  (if (= (string.sub str 1 1) "@")
      (let [s (tonumber (string.sub str 2 17) 16)
            two_62 (lshift 1 62)
            sec (if (>= s two_62)
                    (- s two_62)
                    (- two_62 s))
            nano (tonumber (string.sub str 18 25) 16)]
        {:s sec :n nano})
      nil))

(fn to-unix [tai]
  (values (- tai.s (leap-seconds-tai tai.s)) tai.n))

(fn from-unix [seconds nanos]
  (let [s (math.floor seconds)
        ;; subsecond value may be given as fraction or as a separate
        ;; param, but not both
        n (or nanos (* (- seconds s) 1e9))]
    { :s
      (+ s (leap-seconds-unix s))
      :n n }))

(define-tests
  (expect=
   (from-timestamp "@4000000068e2f0d3257dc09b")
   {:s 1759703251 :n 628998299})

  (let [(s n) (to-unix (from-timestamp "@4000000068e2f0d3257dc09b"))]
    (expect= [s n] [1759703214 628998299]))

  (let [{ : s : n } (from-unix 1759703214 1e6)]
    (expect= [s n] [1759703251 1e6]))

  (let [{ : s : n } (from-unix 1759703214.5)]
    (expect= [s n] [1759703251 5e8]))

  ;; check the leap second count is looked up correctly around a
  ;; boundary
  (let [unix (os.time {:year 2016 :month 12 :day 31 :hour 23 :min 59 :sec 58})
        tai (from-unix unix)]
    (expect= (- tai.s unix) 36))
  (let [unix (os.time {:year 2016 :month 12 :day 31 :hour 23 :min 59 :sec 63})
        tai (from-unix unix)]
    (expect= (- tai.s unix) 37))
  )


{ : from-timestamp : to-unix : from-unix }
