#pragma rtGlobals=1		// Use modern global access method.

//030119 Kota Miura
//migrated program of Fisher's method for circular statistics:
//original version was "GradStat.ipf
//--myu_kappa() rewritten as a function
//	- X_bar and delta restated as global variables to use them in different function

//010830
// 1. A mistake found in myu_kappa. myu (x_bar=myu is always confined to -90- 90 degrees)
// 2. Use of C_bar (cosine average) in finding kappa 
//is neglected: in case where the cosine average is less than 0, the result returns 
//negative value.

// 000218 Kota Miura
// For the analyis of phototaxis and thermotaxis of slug
//
//A circular random variable theta has a von Mises distribution. Based on the equation by von Mises (1972)
//following statics is possible.

//µ:		the mean direction
//delta:	confidence interval of µ
//kappa:	concentration parameter whose magnitude controls the extent to which random values of theta are clustered around the mean
//confidence interval of kappa

//see details for the Fisher's document.

//    ***************macro "phototaxis_hist (pathname,datafilename)"******************
//	load text file with xy coordinates.
//	1st row= direction of the light
//	2n row=  xy coordinates of the starting point of the nth slug
//	2n+1row= xy coordinates of the ending point of the nth slug

//	angle between lightsource-startpoint axis and startpoint-end point is caliculated in radian.
//	angle is 0rad if slug migrated exactly towards the light source.

//	angle distribution in both deg and radian is shown in Histgram.
//**********************************************************************************************

//CircularStatistics2D(anglewave) written 030120
//confidence limits according to J. H. Zar (1999) "Biostatistical Analysis" 4th edition, Prentice Hall New Jersey
//
//modified to tolerate 1D anglewave
Function CircularStatistics2D(anglewave,angleunit)		
	wave anglewave
	variable angleunit				//if RAD=1, DEG=2
	variable i,j
	variable Nx=Dimsize(anglewave,0)
	variable Ny=Dimsize(anglewave,1)
	variable N
	//print Nx
	//print Ny
	Duplicate/O anglewave temp1Danglewave
	if (Ny!=0)
		redimension/N=(Nx*Ny) temp1Danglewave
		N=Nx*Ny
	else
		N=Nx
		print "1D %g",N
	endif
	Duplicate/O temp1Danglewave sine_ang,cosine_ang

	variable sine_ave,cosine_ave
	NVAR/z r_value
	if (NVAR_exists(r_value)==0)
		variable/G r_value
	endif
//	sine_ang[]=( (numtype(temp1Danglewave[p])==0) ? sin(temp1Danglewave[p]) : 0)
//	cosine_ang[]=( (numtype(temp1Danglewave[p])==0) ? cos(temp1Danglewave[p]) : 0)
	if (angleunit==1)
		sine_ang[]=sin(temp1Danglewave[p])
		cosine_ang[]=cos(temp1Danglewave[p])
	else
		sine_ang[]=sin(temp1Danglewave[p]*pi/180)
		cosine_ang[]=cos(temp1Danglewave[p]*pi/180)
	endif
	Killwaves temp1Danglewave
	
	wavestats/q sine_ang
//	sine_ave=sum(sine_ang,0,(N-1))/N
	sine_ave=V_avg
	wavestats/q cosine_ang
//	cosine_ave=sum(cosine_ang,0,(N-1))/N
	cosine_ave=V_avg
	r_value=sqroot2(sine_ave,cosine_ave)
	
	NVAR/z dispersion_s_deg
	if (NVAR_exists(dispersion_s_deg)==0)
		variable/G dispersion_s_deg
	endif
	dispersion_s_deg=sqrt(2*(1-r_value))*180/pi			//angular deviation defined by Batschelet(1965,1981) and Zar (1999)
	
	variable XO_bar
	NVAR/Z  X_bar
	if (NVAR_exists(X_bar)==0)
		Variable/G X_bar
	endif
	XO_bar=atan(sine_ave/cosine_ave)
	//Print "sine_ave "+num2str(sine_ave)+", cos_ave"+num2str(cosine_ave)
	
//	If (cosine_ave<0)							//these parts were added (010830)
//		if (sine_ave<0 )
//			XO_bar=XO_bar-pi
//		else							//sine_ave>0
//			XO_bar=XO_bar+pi
//		endif
//	endif

	If (cosine_ave<0)							//above section is modified for 0-360degrees 030119
		if (sine_ave<0 )
			XO_bar=XO_bar+pi
		else							//sine_ave>0
			XO_bar=XO_bar+pi
		endif
	else
		if (sine_ave<0)
			XO_bar=XO_bar+2*pi
		endif
	endif	
	//	XO_bar=XO_bar+pi
	//else					// cosine_ave>0

	//endif

	X_bar=XO_bar/pi/2*360
	NVAR isPosition
	if ((isPosition==1) && (X_bar>180))
		X_bar=-1*(360-X_bar)
	endif

	variable delta
	variable chi_squared=6.635			// chi-squared (alpha,1) for the 95% confidence limits (alpha=0.05). 
									// for 90% 2.706, 95% (normaly used ) 3.841
									// for 99 %, 6.635, 99.9% 10.828 ---see Zar(1999) appendix table B1 
	if (n<8)
		print "confidence limits cannot be calculated since n<8"
		delta=NaN
	else
		if (r_value<=sqrt(chi_squared/2/N))
			print "confidence limits cannot be calculated since sample is dispersed too much"
			delta=NaN
		else
			Variable LR=N*r_value
			if (r_value<=0.9)
				delta=acos( sqrt( ( 2*N*(2*LR^2-N*chi_squared ) )/ (4*N-chi_squared) )/LR )
			else
				delta= acos(sqrt(N^2-(N^2-LR^2)*e^(chi_squared/N)) / LR) 
			endif
		endif
	endif
	NVAR/z delta_deg
	if (NVAR_exists(delta_deg)==0)
		variable/G delta_deg
	endif
	delta_deg=delta/pi/2*360
	
	X_bar=round(X_bar)
	delta_deg=round(delta_deg)
//	printf "%s: ",nameofwave(anglewave)
//	printf "Mean [deg] =%g ±%g (0.99 confidence limits)  ", x_bar,delta_deg
//	printf "Angular Deviation [deg] %g  ",dispersion_s_deg	
//	print "Concentration parameter r "+num2str(r_value)
	
	killwaves sine_ang,cosine_ang
END



Function LoadLib_myuK()

	LoadData /D/I/L=1 "myu_kappa_lib"

//	 table2_3Kappa.ibw			
//	 table2_6deltadash		
//	 table2_6kappa		
//	 append278,append2710,//more
//	 append27x8,append27x10,//more

//	 table1L0,table1L5,table1L10,table1L15,table1L20,table1L25,table1L30, table1L35,table1L40,table1L45,table1L50		
//	 table1U0,table1U5,table1U10,table1U15,table1U20,table1U25,table1U30, table1U35,table1U40,table1U45,table1U50	
//	 table2U0,table2U5,table2U10,table2U15,table2U20,table2U25,table2U30, table2U35,table2U40,table2U45,table2U50	
//	 table2L0, table2L5, table2L10, table2L15, table2L20,table2L25, table2L30, table2L35, table2L40, table2L45, table2L50	
//	 table1_column.ibw,table1_n
//	 table1_samplenumSQRTinv		
//	table1_columnshort
//	 chisquare_up		
//	 chisquare_low		

END

// ********** Macro kappa (anglewave)****************
//
// Stastical analysis to derive kappa and error. Fisher's method (1981)
//
//


Function myu_kappa (anglewave)
 	Wave  anglewave
	String  openfile_27a,openfile_27atab,openfile_27b,openfile_27btab
	String  open_table_upper,open_table_lower
	String  tempwaveULname,tempwaveLLname
	Variable	i,j,k, n, sine_int,cosine_int,sine_ave,cosine_ave		//n is the number of sample
	Variable	R_bar
	Variable  XO_bar//,X_bar				// maximum likelihood of µ0. (µ0 roof)
	NVAR/Z  X_bar
	if (NVAR_exists(X_bar)==0)
		Variable/G X_bar
	endif
	Variable  kappa_roof,Kappa_dash
	Variable  c_bar
//	Variable delta	,delta1,delta2				// confidence interval for µ0
	Variable delta1,delta2				// confidence interval for µ0
	NVAR/z delta
	if (NVAR_exists(delta)==0)
		Variable/G delta
	endif
	Variable PDF							//probability density function for the confidence limits for kappa. In Paul's programm, cosAV
	Variable x_kappa,variance_kappa,x_kappa_lowlimit,x_kappa_uplimit
	Variable gamma,chisqua
	Variable Ndef,chisquare_upper,chisquare_lower
	Variable n1,n2,a,b,u,v //used for caliculating kappa confidence limits with chi-square distributuion
	Variable invsqrtN,table_n_below,table_n_above,table_n_below_X,table_n_above_X

	i=0
	n=numpnts(anglewave)
	do
		sine_int=sine_int+sin(anglewave[i])
		cosine_int=cosine_int+cos(anglewave[i])
		i=i+1
	while (i<n)
	
	sine_ave=sine_int/n
	cosine_ave=cosine_int/n
	R_bar=sqrt(sine_ave^2+cosine_ave^2)
	XO_bar=atan(sine_ave/cosine_ave)
	Print "sine_ave "+num2str(sine_ave)+", cos_ave"+num2str(cosine_ave)
	
	If (cosine_ave<0)							//these parts were added (010830)
		if (sine_ave<0 )
			XO_bar=XO_bar-pi
		else							//sine_ave>0
			XO_bar=XO_bar+pi
		endif
	endif
	//	XO_bar=XO_bar+pi
	//else					// cosine_ave>0

	//endif

	X_bar=XO_bar/3.1415/2*360				//µ: depends on where willl be the center. in this case, start-light axis is 180grad
	
// **********maximum likelihood estimate Kappa_roof**************

	kappa_roof=GetKappa(R_bar,table2_3Kappa)			//function defined below

//*********confidence interval for µ0 (delta)****************
	if (n>30)
		Kappa_dash=kappa_roof*R_bar*n
		print "kappa_dash="+num2str(kappa_dash)
		If (kappa_dash >10)
			delta=2.57583/sqrt(kappa_dash-0.5)/2/pi*360					//alpha is 0.005, 0.5% of the normal distribution
		else
			delta=180-interp(kappa_dash,table2_6kappa,table2_6deltadash) 		 //linear interpolation of table2.6, which should be loaded.
		endif
	else
			// in case of n<=30, then refer to the tables 2.71-2.78
			// in the table, first column is R_bar and the second is delta.
			// get delta1 from 2.71, delta2 from 2.72, so on
		If (n<8)
			Delta=999.999
			Print "Sample too small (<8) to find delta"
		else
			i=8
			if ((n>=8) %& (n<20)) 
				do
					if ((i<=n) %& (n<(i+2)))
						n1=i
						n2=i+2
					endif
					i=i+2
				while (i<=18)
			else
				if (n>=20)
			  		n1=20
			  		n2=30
				endif
			endif
			openfile_27a="append27"+num2str(n1)							//wavenames in the form of  append278, append27x8, append2710....
			openfile_27atab="append27x"+num2str(n1)
			openfile_27b="append27"+num2str(n2)
			openfile_27btab="append27x"+num2str(n2)			
			print num2str(n1)
			print num2str(n2)
			delta1=interp(R_bar, $openfile_27atab, $openfile_27a)
			delta2=interp(R_bar, $openfile_27btab, $openfile_27b)
			print num2str(delta1)
			print num2str(delta2)
			If ((delta1==0)	 %| (delta1==-inf))												//outside the range in both cases
				if ((delta2==0)%| (delta1==-inf))
					delta=90
				else
					delta=delta2
				endif
				print "Delta >"+num2str(delta)+" ::outside the range of Append2.7"
			else
				delta=linear_interpolate(n, n1, n2, delta1, delta2)				//function defined below
			endif
		endif
		
	endif

//*************kappa**********************

	c_bar=cosine_ave
	
	//If ( (n==1) %| ( (delta!=999.999) %& ( ((x_bar-delta)<=(-180)) %& ((-180)<=(x_bar+delta)) %| ((x_bar-delta)<=180) %& (180 <= (x_bar+delta)) ) ) )
		//PDF=C_bar				// µ0 is known
               // print "c_bar (cosine ave) is taken"	
	//else
		PDF=R_bar				//µo is unknown
	//endif
						//use of c_bar is omitted (010830)
	x_kappa=GetKappa(PDF,table2_3Kappa)
	
	If (PDF < 0)
		Variance_kappa=2*ln(-1*PDF)
	else
		If (PDF==0)
			variance_kappa=99999.999
		else
			Variance_kappa=(-2)*ln(PDF)
		endif
	endif
//**********find 90% confidence limits for kappa***********************

	If (x_kappa<2)						//this section is the problem 
		If (n<5)
			x_kappa_lowlimit=0
			x_kappa_uplimit=99999.999
			print "sample too small to find kappa confidence limits"
		else
			If (PDF==C_bar)
				open_table_upper="table1U"
				open_table_lower="table1L"
			else		//	(PDF=R_bar)
				open_table_upper="table2U"
				open_table_lower="table2L"
			endif
			i=0
			invsqrtN=1/sqrt(n)
			if (PDF==R_bar)
				make /N=10 tempColumnUL
				make /N=11 tempcolumnLL
			else
				make /N=11 tempColumnUL,tempcolumnLL
			endif

			wave/z table1_samplenumSQRTinv,table1_n	//030119
			
			if  (n> 999)
				table_n_below=table1_samplenumSQRTinv[13]
				table_n_above=0
				table_n_below_X=13						//lower limit point in the table
				table_n_above_X=14						//upper limit point in the table
			else
				do
					if ((table1_n[i]<=N) %& (N<table1_n[i+1]))
							table_n_below_X=i											//lower limit point in the table
							table_n_above_X=i+1											//upper limit point in the table						
							table_n_below=table1_samplenumSQRTinv[i]						//lower limit for Y axis in the table
							table_n_above=table1_samplenumSQRTinv[i+1]					//upper limit for Y axis in the table
					endif
					i=i+1
				while (i<15)

			endif
			i=0
			if (PDF==R_bar)
				j=0.5
				k=10
			else
				j=0
				k=11
			endif
			do
				tempwaveULname=open_table_upper+num2str(10*j)
				wave/z 	tempwaveUL=$tempwaveULname			
				tempColumnUL[i]=linear_interpolate(invsqrtN,table_n_below,tempwaveUL[table_n_below_X],table_n_above,tempwaveUL[table_n_above_X])				
				i=i+1
				j=j+0.5
			while (i<k)

			i=0
			j=0		
			do
				tempwaveLLname=open_table_lower+num2str(10*j)
				wave/z  tempwaveLL=$tempwaveLLname		//030119
//				tempColumnLL[i]=linear_interpolate(invsqrtN,table_n_below,$tempwaveLL[table_n_below_X],table_n_above,$tempwaveLL[table_n_above_X])
				tempColumnLL[i]=linear_interpolate(invsqrtN,table_n_below,tempwaveLL[table_n_below_X],table_n_above,tempwaveLL[table_n_above_X])
				i=i+1
				j=j+0.5
			while (i<11)
			
			if (PDF==R_bar)
				If (PDF<tempColumnUL[0])
					x_kappa_uplimit=0.5
					print "R_bar too small to find Upperlimit of Kappa: extrapolated: should be less than 0.5"
				else
					x_kappa_uplimit=interp(PDF, tempColumnUL,table1_columnshort)
				endif
			else
				x_kappa_uplimit=interp(PDF, tempColumnUL,table1_column)
			endif		
				
			If (PDF<tempColumnLL[0])
				x_kappa_lowlimit=0
				print "R_bar too small to find Lowerlimit of Kappa: LowLimit set as 0"
			else
				x_kappa_lowlimit=interp(PDF, tempColumnLL,table1_column)
			endif
			
			Killwaves tempColumnUL,tempcolumnLL
			
		endif
	else
		If (PDF==C_bar)
			Ndef=n
		endif
		If (PDF==R_bar)
			Ndef=n-1
		endif
		If (PDF==1)
			x_kappa_lowlimit=0
			x_kappa_uplimit=99999.999
			print "R_bar or C_bar equals 1, kappa confidence limits undefined"
		else
		wave/z chisquare_low,chisquare_up
			if (Ndef<=30)
				Chisquare_Lower=chisquare_low[Ndef]	//loaded wave 95%confidence limits (see the original table) However the confidence limit for kappa is within 90%
				Chisquare_Upper=chisquare_up[Ndef]	//loaded wave
			else
				u=1.64485							// taken from the normal distribution; Pr(U>u-alpha)=0.05
				v=2/9/Ndef							// for n>30, approximate formula is applied (see the original)
				Chisquare_Lower=Ndef*(1-v-u*sqrt(v))^3	//sign of u reverses since it is lower limit.
				Chisquare_Upper=Ndef*(1-v+u*sqrt(v))^3
			endif
			
			//gamma=1/((x_kappa)^(-1)+3/8*(x_kappa)^(-2))		//method described in fisher's document, different from the program 
			//chisqua=2*gamma*(Ndef-PDF)
			//a=(n-PDF)/chisqua/0.95
			//b=(n-PDF)/chisqua/0.05
			
			A=n*(1-PDF)/Chisquare_Lower
			B=n*(1-PDF)/Chisquare_Upper
			x_kappa_lowlimit=(1+sqrt(1+3*A))/4/A
			x_kappa_uplimit=(1+sqrt(1+3*B))/4/B
		endif
	endif
	
	print " N = "+num2str(n)
	print " R_Bar = "+num2str(R_bar)
	print " C_Bar = "+num2str(C_Bar)
	print " µ [deg] = "+num2str(x_bar)+" ± "+num2str(delta)
	print " µ [rad] = "+num2str(x_bar/360*2*3.1415)+" ± "+num2str(delta/360*2*3.1415)
	print " Kappa = "+num2str(x_kappa)
	print " Kappa Upper Limit: "+num2str(x_kappa_uplimit)
	Print " Kappa Lower Limit: "+num2str(x_kappa_lowlimit)
	print " Kappa variance=	"+num2str(variance_kappa)

END
	
	
//***************Functions****************************
			
		        			
Function sqroot4(a,b,c,d)
	variable a,b,c,d
	return ((a-c)^2+(b-d)^2)^(0.5)
END

Function sqroot2(a,b)
	variable a,b
	return sqrt(a^2+b^2)
END

Function linear_interpolate(x_point,a,b,c,d) // from 2 points (a,b) and (c,d)
	variable x_point,a,b,c,d
	return (d-b)/(c-a)*x_point-(d-b)/(c-a)*a+b
END
	
Function GetKappa(R_bar_global,table2_3)
	variable R_bar_global
	wave table2_3
	
	If (R_bar_global< 0.45)
		return R_bar_global/6*(12+6*(R_bar_global)^2+5*(R_bar_global)^4)
	endif
	If (R_bar_global==1)
		return 99999.999
	else
		If (R_bar_global>0.8)
			return 1/(2*(1-R_bar_global)-(1-R_bar_global)^2-(1-R_bar_global)^3)
		endif
	endif
	if ((R_bar_global>=0.45) %& (R_bar_global<=0.8))
		return table2_3(R_bar_global)			//from loaded wave
	endif
END

//***************************************************************