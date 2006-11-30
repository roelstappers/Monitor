// Input file

title = "Surface verification"

framec="Goldenrod"

v[0] = ['PS_00000000','V_00000000','v_00000000','f_00000000']
t[0] = ['Timeserie stat','Fc length ver','Dayvar','Freq dist.']

v[1] = ['00000000']
t[1] = v[1]

v[2] =[1] ;
t[2] = v[2] ;


v[3] = [0,1,2,3,4,5,6]
t[3] = ['Wind speed','Wind dir','PMSL','T2m','Rh2m','q2m','Cloud cover']

v[4] =[0] ;
t[4] = v[4] ;
v[5] =[0] ;
t[5] = v[5] ;

mname = ["Type","Station","dum","Parameter","Level","Exp"]
help = "Different models:       <br> G05: HIRLAM, 5.5km, 60 levels, H      <br> UM4: UM, 4.0km, 38 levels, NH      <br> al00: ALADIN, 11km, 60 levels, H"; hide_help = false ;

pdir ="http://www.smhi.se/sgn0106/if/hirald/WebgraF/MODINT/Surface/"
ext='png'
do_send = true ;

