#pragma rtGlobals=1		// Use modern global access method.

//021229 Kota Miura
//following is functions selected for "Vec9_CustomMeas2.ipf"
//redundant with the main program
//041129 modified for new functions (bleaching, STLO stuff)

Function/S V_Prefix()
	SVAR wavename_pref
	NVAR Unit
	String prefix
	prefix=wavename_pref+"U"+num2str(Unit)+"_"
	return prefix
END
//***
Function/S StatnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process
	return wave_name
END

Function/S StatHISTnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process+"H"
	return wave_name
END


Function VectorFieldDerive()		//copied from VEC9_core 041129
	SVAR	wavename_pref
	NVAR	unit,LayerStart,LayerEnd
	NVAR bleachrate		//031203
	NVAR OptimizationMethod //041129
	Variable	filenum,n,truncation,WorkingLayerNumber
	Variable	rownumber,columnnumber,layernumber
	String	w,filename,currentwavename,VXname,VYname
	String	firstwavename,wavenamea
	
	//PRINTF num2str(unit)
	//following calculation are done at the root directory
	wavenamea="Mat"+wavename_pref
	Wave originalMatrix=$wavenamea

	rownumber=DimSize(originalMatrix, 0)
	columnnumber=DimSize(originalMatrix, 1)
	layernumber=DimSize(originalMatrix, 2)

	if (LayerEnd>(layernumber-1))
		layerEnd=layernumber-1
	endif
	
	WorkingLayerNumber=LayerEnd-LayerStart+1
	truncation=unit-1
	
 	Make/N=(rownumber-truncation,columnnumber, WorkingLayerNumber) derXsub
	Make/N=(rownumber,columnnumber-truncation, WorkingLayerNumber) derYsub
	Make/N=(rownumber,columnnumber, WorkingLayerNumber-truncation) derTsub
	
	derXsub[][][]=(originalMatrix[p+truncation][q][r+LayerStart]-originalMatrix[p][q][r+LayerStart])/2
	derYsub[][][]=(originalMatrix[p][q+truncation][r+LayerStart]-originalMatrix[p][q][r+LayerStart])/2
	derTsub[][][]=(originalMatrix[p][q][r+LayerStart+truncation]-originalMatrix[p][q][r+LayerStart])/2

 	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derX_subave
	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derY_subave
	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derT_subave
	
	if (unit==3)
		derX_subave[][][]=(derXsub[p][q][r]+derXsub[p][q+1][r]+derXsub[p][q+2][r]+derXsub[p][q][r+1]+derXsub[p][q+1][r+1]+derXsub[p][q+2][r+1]+derXsub[p][q][r+2]+derXsub[p][q+1][r+2]+derXsub[p][q+2][r+2])/9
		derY_subave[][][]=(derYsub[p][q][r]+derYsub[p+1][q][r]+derYsub[p+2][q][r]+derYsub[p][q][r+1]+derYsub[p+1][q][r+1]+derYsub[p+2][q][r+1]+derYsub[p][q][r+2]+derYsub[p+1][q][r+2]+derYsub[p+2][q][r+2])/9
		derT_subave[][][]=(derTsub[p][q][r]+derTsub[p+1][q][r]+derTsub[p+2][q][r]+derTsub[p][q+1][r]+derTsub[p+1][q+1][r]+derTsub[p+2][q+1][r]+derTsub[p][q+2][r]+derTsub[p+1][q+2][r]+derTsub[p+2][q+2][r])/9
	else
		derX_subave[][][]=(derXsub[p][q][r]+derXsub[p][q+1][r]+derXsub[p][q][r+1]+derXsub[p][q+1][r+1])/4
		derY_subave[][][]=(derYsub[p][q][r]+derYsub[p+1][q][r]+derYsub[p][q][r+1]+derYsub[p+1][q][r+1])/4
		derT_subave[][][]=(derTsub[p][q][r]+derTsub[p+1][q][r]+derTsub[p][q+1][r]+derTsub[p+1][q+1][r])/4
	endif

	Killwaves derXsub,derYsub,derTsub

// Finished partial derivation

	Vec_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber) 	//041129
	Vec_ErrorElimination()
END


//********************
Function Vec_ErrorElimination()		//copied from VEC9_core 041129
	
	wave/z VX,VY
	Duplicate/o VX tempVX,VX_error,tempVX_speed,tempnull	//041129 overwrite
	Duplicate/o VY tempVY,VY_error	//041129 overwrite
	
	tempnull[][]=0
	tempVX[][]=((tempVX[p][q]==Nan) ? (0) : (tempVX[p][q]) )
	tempVY[][]=((tempVY[p][q]==Nan) ? (0) : (tempVY[p][q]) )
	tempVX_speed[][]=(sqroot(tempnull[p][q],tempnull[p][q],tempVX[p][q],tempVY[p][q]))

	VX[][]=((numtype(tempVX_speed[p][q]) == 1) ? NaN :(VX[p][q]))			//* delete inf speed VX
	VY[][]=((numtype(tempVX_speed[p][q]) == 1) ? NaN :(VY[p][q]))			//* delete inf speed VY
	tempVX_speed[][]=((numtype(tempVX_speed[p][q]) == 1) ? NaN :(tempVX_speed[p][q]))			//* delete inf

	VX[][]=(( tempVX_speed[p][q]>30 ) ? NaN :(VX[p][q]))					// cut off data above 30 (error level) 
	VY[][]=(( tempVX_speed[p][q]>30 ) ? NaN :(VY[p][q]))
	KillWaves tempVX,tempVY,tempnull,tempVX_speed
END


Function/s RenameTiffToMAT()
	String MATlist
	Matlist=WaveList("*.tif", ";", "" )
	Variable n= ItemsInList(Matlist)
	variable i
	variable namelength
	string imagename,newimagename
	for (i=0; i<n; i+=1)
		imagename=StringFromList(i,MATlist)
		newimagename="MAT"+imagename[0,(strlen(imagename)-5)]
		rename $imagename,$newimagename
	endfor
	return newimagename
END

Function sqroot(a,b,c,d)
	Variable a,b,c,d
	return ((a-c)^2+(b-d)^2)^(0.5)
end

Function HistStatParameterInit()
	String/G AbsoluteOrRelative="\Z08Absolute"
	variable/G isPosition=0
	Variable/G gSpeed_Threshold=0
	Variable/G Dest_X=0
	Variable/G Dest_Y=0
	Variable/G G_AllStatFinished=0
	Variable/G G_upper_limit=30
	Variable/G G_lower_limit=0
END




///************ for filtering
// copied from VEC92Dhist_anal

Function V9_checkSameDim2D(src2Dwave1,src2Dwave2)		//fin
	wave src2Dwave1,src2Dwave2
	variable same=0
	if ( (Dimsize(src2Dwave1,0)==Dimsize(src2Dwave2,0)) && (Dimsize(src2Dwave1,1)==Dimsize(src2Dwave2,1)))
		same=1
	endif
	return same
end

Function V9_GenerateMask(src2DWave,destMask2Dwave,val_min,val_max)
	wave src2DWave,destMask2Dwave
	Variable val_min,val_max
	if (V9_checkSameDim2D(src2DWave,destMask2Dwave)==0)
		Abort "error in V9_GenerateMask(src2DWave,destMask2Dwave,val_min,val_max): not same dimension"
	endif	
	destMask2Dwave=0
	destMask2Dwave[][]=( ((val_min<=src2Dwave[p][q] ) && (src2Dwave[p][q] <= val_max)) ? 1 : 0)
END

// copied from VEC92Dhist_anal

Function Vec_V2DFilter_v2(maskwave)
	wave maskwave
	wave/z VX,VY
	if (V9_checkSameDim2D(maskwave,VX)==0)
		Abort "error in Vec_V2DFilter_v2(maskwave): not same dimension"
	endif	
	Duplicate/o VX VX_filtered
	Duplicate/o VY VY_filtered
	//V9_initializeAnalysisFolder()
	VX_filtered[][]=(maskwave[p][q]==1 ? VX[p][q] : NaN)		
	VY_filtered[][]=(maskwave[p][q]==1 ? VY[p][q] : NaN)		
END

/////**********copied from VEC9_imageprocesing
// 020901 Kota Miura
// for 2D hist plot analysis
// copied and modifidied VEC9_imageporcessing modules

Function V9_Zprojection_MAX(src3Dwave,des2Dwave,slices,frame)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	variable slices,frame			//slices:=per time point; frame=:time point
	variable i,currentValue
	wavestats/Q src3Dwave
	des2Dwave=V_min				
	for (i=0; i<slices; i+=1)
		des2Dwave[][]=( (des2Dwave[p][q]<src3Dwave[p][q][frame+i]) ? (src3Dwave[p][q][frame+i]) : (des2Dwave[p][q]) )
	endfor
END

Function V9_Zprojection_MIN(src3Dwave,des2Dwave,slices,frame)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	variable slices,frame			//slices:=per time point; frame=:time point
	variable i,currentValue
	wavestats/Q src3Dwave
	des2Dwave=V_max				
	for (i=0; i<slices; i+=1)
		des2Dwave[][]=( (des2Dwave[p][q]>src3Dwave[p][q][frame+i]) ? (src3Dwave[p][q][frame+i]) : (des2Dwave[p][q]) )
	endfor
END



Function/S V9_DetermineBackground(src3Dwave)
	wave src3Dwave
	//Make/O/N=(DimSize(src3Dwave,0),DimSize(src3Dwave,1)) temp2Dwave
	//temp2Dwave=src3Dwave[p][q][0]
	variable binwidth,binnumber
	//wavestats/Q temp2Dwave
	wavestats/Q src3Dwave
	binnumber=3			//if to change, here is the place!
	binwidth =((V_max-V_min)*1.1/binnumber)			//changed 030114
	Make/O/N=(binnumber) tempHIST
	Histogram/B={V_min,binwidth,binnumber} src3Dwave,tempHist
	string DeterminationString
//	print tempHIST[0]
//	print tempHIST[binnumber-1]
	if (tempHIST[0]>tempHist[binnumber-1])
		DeterminationString="LOW"
	else
		DeterminationString="HIGH"
	endif
//	Printf "Background is %s",DeterminationString
	//Killwaves temp3Dwave,tempHIST
	//Killwaves tempHIST
	return DeterminationString
END

Function V9_ZprojectionFirstFrame(src3Dwave,des2Dwave,LayerStart,LayerEND)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	Variable LayerStart,LayerEND
	variable slices			
	slices=LayerEnd-Layerstart+1
	String Background=V9_DetermineBackground(src3Dwave)
	if (cmpstr(Background,"LOW")==0)
		V9_Zprojection_MAX(src3Dwave,des2Dwave,slices,Layerstart)
	else
		V9_Zprojection_MIN(src3Dwave,des2Dwave,slices,Layerstart)
	endif
END

//*****************************
//copied from Vec9_vonMisesStat.ipf		0301120

Function CircularStatistics2D(anglewave,angleunit)		//for 2D angle wave in radian
	wave anglewave
	variable angleunit				//if RAD=1, DEG=2
	variable i,j
	variable Nx=Dimsize(anglewave,0)
	variable Ny=Dimsize(anglewave,1)
	variable N=Nx*Ny
	Duplicate/O anglewave temp1Danglewave
	redimension/N=(Nx*Ny) temp1Danglewave
	
	Duplicate/O temp1Danglewave sine_ang,cosine_ang
	variable sine_ave,cosine_ave,r_value
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
	
	variable dispersion_s_deg
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
//	printf "Mean [deg] =%g ±%g (0.99 confidence limits)  ", x_bar,delta_deg
//	printf "Angular Deviation [deg] %g  ",dispersion_s_deg	
//	print "Concentration parameter r "+num2str(r_value)
	
	killwaves sine_ang,cosine_ang
END

Function sqroot2(a,b)
	variable a,b
	return sqrt(a^2+b^2)
END