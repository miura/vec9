#pragma rtGlobals=1		// Use modern global access method.

// 021228 started development for analyzing multiple dot animation stacks.
// the idea is to import multiple stacks, get vector field, do statistics (with filtering)

#include "VEC9_SpeciMeasure"
#include "VEC9_CustomMeas2b"
#include "Vec9_customMeas2_noise"
//#include "Vec9_core"	//041129
#include "Vec9_core02"	//041129

//Menu "Custom Vec Measure"
//	
//	V9_BatchVectorFieldAnalysis(intensity,direction,L_unit,frames,pathname)
//		--> varied size and velocity
//same above but no loops for dotsize
//Function V9_BatchVectorFieldAnalysis2(intensity,direction,dotsize,L_unit,frames,pathname)
//end

//analysis stuff
// utility to show a graph
//V9_DisplayGraphs(intensity,direction)
// V9_DisplayAVGraphs(intensity,direction)
//
//V9_DisplayGraphsDirectionality(intensity,direction,size)		//this goes until Layout formation.
//V9_differentDotSize(intensity,direction)		//030217
// V9_differentIntensity(direction,dotsize)		//030217 -2
// V9_differentIntensityALL(dotsize)		//030217 -3

//DoAllDotSizeSameInt(intensity,direction,rangeV,rangeG)	
//		-- FindRangeInErrorDirection(srcwave,direction,range)
//DoAllwithDifInt(direction,rangeV,rangeG)

//V9_FindRangeFit_summarize()	
//V9_FindRangeFit_summarize()		//030217			for making graphs (Vmax and Vslope range finding)
//V9_FindRangeFitSpec(size,direction,intensity)  //singular mode of the above loop



//		IMPORTING FILES
Function/s RenameTiffToMATNew(tif_filename)
	String tif_filename
	string newimagename
	newimagename="MAT"+tif_filename[0,(strlen(tif_filename)-5)]
	rename $tif_filename,$newimagename
	return newimagename
END

Function V9_LoadSpecifiedStack(pathname,wavename_pref)
	string pathname,wavename_pref
	print "loading started"
//	ImageLoad/C=-1/S=0/T=tiff/P=$pathname/z wavename_pref
	ImageLoad/O/Z/C=-1/S=0/T=tiff/P=$pathname wavename_pref
	//print "loading finished"
	return V_Flag
END



//generating dot anime stack file name
Function/s V9_GenerateFilename(intensity,direction,dotsize,velocity)
	variable intensity,direction,dotsize,velocity
	string filename
	filename="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2Str(velocity)+".tif"
	print filename
	return filename
end

Function/s V9_GenerateFilenameSN(intensity,direction,dotsize,velocity,noise)	//030227
	variable intensity,direction,dotsize,velocity,noise
	string filename
	filename="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2Str(velocity)+"N"+num2str(noise)+".tif"
	print filename
	return filename
end

//**************************
Function/s V9_Generate3Dwavename(intensity,direction,dotsize,velocity)
	variable intensity,direction,dotsize,velocity
	string filename
	filename="MATI"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2Str(velocity)
	print filename
	return filename
end

// copied from VEC9_DatafolderIO	041129
Function/s V9_Original3Dwave()
	SVAR wavename_pref
	return ("root:MAT"+wavename_pref)
END

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Function FilteredVecFieldDerive()		//030114
	SVAR wavename_pref
	NVAR LayerStart,LayerEND
	string MatrixWavename="Mat"+wavename_pref
	wave/z Matrix3D=$MatrixWavename
	String Mat3DProjName=MatrixWavename+"_Proj"
	Make/n=(Dimsize(Matrix3D,0), DimSize(Matrix3D,1)) $Mat3DProjName
	wave/z Mat3DProj=$Mat3DProjName
	V9_ZprojectionFirstFrame(Matrix3D,Mat3DProj,LayerStart,LayerEND)
	NVAR unit
	Duplicate/O/R=[trunc(unit/2),(Dimsize(Mat3DProj,0)-trunc(unit/2)-1)][trunc(unit/2),(Dimsize(Mat3DProj,1)-trunc(unit/2)-1)] Mat3DProj, tempCrop
	wave/z TC=$("tempCrop")
	Duplicate/O TC, FilterProj
//	Duplicate/O Mat3DProj, Filterproj
	Wave/z FP=$("filterProj")
	NVAR G_IntMin,G_IntMax
//	V9_GenerateMask(Mat3DProj,FP,G_IntMin,G_IntMax)
	V9_GenerateMask(TC,FP,G_IntMin,G_IntMax)
	Vec_V2DFilter_v2(FP)
	wave/z VX_filtered,VY_filtered
	V9_averagingCoreShort(VX_filtered,VY_filtered,3)
	HistAnalCoreSimple2(1)
	killwaves Mat3DProj,FP,TC
END
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//***********************
FUnction/s V9_singleVecField(matrix3D,L_unit,frames)
	wave matrix3D
	variable L_unit,frames
	
	string L_wavename_pref=nameofwave(matrix3D)
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])
	if (L_unit==1)
		L_unit=3
	elseif (L_unit==2)
		L_unit=2
	endif

	variable L_LayerStart=0
	variable L_LayerEnd=L_LayerStart+frames-1
	variable L_button_bleachcorrect=0		//041129
	variable L_OptimizationMethod=1		//041129 STLO 3x3	
	String	FolderName//,L_windowname,WindowMatching
	SVAR/z wavename_pref
	NVAR/z Unit,Layerstart,LayerEND,button_bleachcorrect,OptimizationMethod

	if (SVAR_exists(wavename_pref)==0)
		String/G wavename_pref//=L_wavename_pref
		Variable/G Unit//=L_unit
		Variable/G Layerstart//=L_Layerstart
		Variable/G LayerEnd//=L_LayerEnd
		Variable/G button_bleachcorrect,OptimizationMethod
	endif
	wavename_pref=L_wavename_pref
	Unit=L_unit
	Layerstart=L_Layerstart
	LayerEnd=L_LayerEnd
	button_bleachcorrect=L_button_bleachcorrect
	OptimizationMethod=L_OptimizationMethod
	
	VectorFieldDerive()
	wave/z VX,VY
	V9_averagingCoreShort(VX,VY,3)
	HistAnalCoreSimple2(0)		// 021228 newer version in below
				
END

//**************************************************
//020108
Function V9_averagingCoreShort(L_VX,L_VY,averaging)
	Wave/z L_VX,L_VY
	variable	averaging
	NVAR unit
//	Variable/G rnum_im,cnum_im
//	Variable/G	averageshift		//use this parameter when realigning
//	Variable/G rnum_VXY=DimSize(VX, 0)
//	Variable/G cnum_VXY=DimSize(VX, 1)
	Variable	averageshift		
	Variable rnum_VXY=DimSize(VX, 0)
	Variable cnum_VXY=DimSize(VX, 1)

	Variable loop_row,loop_col
	String VXav_name=(NameOfWave(L_VX)+"av")
	String VYav_name=(NameOfWave(L_VY)+"av")

	if (averaging<3)		//matrix filtering should be >3
		averaging=3
	endif

	Variable	ave_rownumber=trunc(rnum_VXY/averaging)
	Variable	ave_columnnumber=trunc(cnum_VXY/averaging)
	Make/O/N=(ave_rownumber,ave_columnnumber) $VXav_name
	Make/O/N=(ave_rownumber,ave_columnnumber) $VYav_name
	
	Wave L_VXav=$VXav_name
	Wave L_VYav=$VYav_name
	
	loop_col=0
	do
			loop_row=0
			do
				Imagestats/G={(loop_row*averaging),(loop_row*averaging+averaging-1),(loop_col*averaging),(loop_col*averaging+averaging-1)} L_VX
				L_VXav[loop_row][loop_col]=V_avg
				Imagestats/G={(loop_row*averaging),(loop_row*averaging+averaging-1),(loop_col*averaging),(loop_col*averaging+averaging-1)} L_VY		
				L_VYav[loop_row][loop_col]=V_avg
				loop_row=loop_row+1
			while (Loop_row<ave_rownumber)
			loop_col=loop_col+1
	while (Loop_col<ave_columnnumber)
	
//	Variable/G rnum=DimSize(L_VXav, 0)
//	Variable/G cnum=DimSize(L_VXav, 1)
	Variable rnum=DimSize(L_VXav, 0)
	Variable cnum=DimSize(L_VXav, 1)

	if (unit==3)
		if ((averaging/2-trunc(averaging/2)) !=0)
			averageshift=trunc(averaging/2)+2
		else
			averageshift=trunc(averaging/2)+1
		endif
	else //unit=2
		if ((averaging/2-trunc(averaging/2)) !=0)
			averageshift=trunc(averaging/2)+1
		else
			averageshift=trunc(averaging/2)
		endif
	endif

	SetScale/P x averageshift,averaging,"", L_VXav,L_VYav
	SetScale/P y averageshift,averaging,"", L_VXav,L_VYav
//	SetScale/P x averageshift,averaging,"", L_VYav
//	SetScale/P y averageshift,averaging,"", L_VYav
	
END

//***********************************************
// shorter version of HistAnalCore: no calculation for the average stuff



Function HistAnalCoreSimple2(Filtering)
	variable Filtering
	NVAR unit,LayerStart,LayerEnd
	SVAR wavename_pref
	String RadWavename,GradWavename,VecLengthWavename,RadWaveAVname,GradWaveAVname,VecLengthWaveAVname
	String RadWavenameHIST,GradWavenameHIST,VecLengthWavenameHIST,RadWaveAVnameHIST,GradWaveAVnameHIST,VecLengthWaveAVnameHIST

	variable  rnum_VXY,cnum_VXY,rnum,cnum
	
	if (Filtering==0)
		Wave/z VX=$("VX"),VY=$("VY"),VXav=$("VXav"),VYav=$("VYav")
		RadWavename="rad"
		GradWavename="deg"
		VecLengthWavename="mag"

		RadWavenameHIST="radH"
		GradWavenameHIST="degH"
		VecLengthWavenameHIST="magH"

		RadWaveAVname="radAV"
		GradWaveAVname="degAV"
		VecLengthWaveAVname="magAV"

		RadWaveAVnameHIST="radAVH"
		GradWaveAVnameHIST="degAVH"
		VecLengthWaveAVnameHIST="magAVH"
	else
		Wave/z VX=$("VX_filtered"),VY=$("VY_filtered"),VXav=$("VX_filteredav"),VYav=$("VY_filteredav")
		RadWavename="radF"
		GradWavename="degF"
		VecLengthWavename="magF"

		RadWavenameHIST="radHF"
		GradWavenameHIST="degHF"
		VecLengthWavenameHIST="magHF"

		RadWaveAVname="radAVF"
		GradWaveAVname="degAVF"
		VecLengthWaveAVname="magAVF"

		RadWaveAVnameHIST="radAVHF"
		GradWaveAVnameHIST="degAVHF"
		VecLengthWaveAVnameHIST="magAVHF"
	endif

	rnum_VXY=DimSize(VX, 0)
	cnum_VXY=DimSize(VX, 1)
	rnum=DimSize(VXav, 0)
	cnum=DimSize(VXav, 1)
	
	//if (exists(VecLengthWavename)==0)
	make/o/n=(rnum_VXY,cnum_VXY) $RadWavename,$GradWavename,$VecLengthWavename
	make/o/n=(rnum_VXY,cnum_VXY) $RadWaveAVname,$GradWaveAVname,$VecLengthWaveAVname
//	make/o/n=(rnum_VXY,cnum_VXY) 
//	make/o/n=(rnum_VXY,cnum_VXY) 

	make/o/n=2 $RadWavenameHIST,$RadWaveAVnameHIST
	make/o/n=2 $GradWavenameHIST,$GradWaveAVnameHIST	
	make/o/n=2 $VecLengthWavenameHIST,$VecLengthWaveAVnameHIST
	//endif
	
	
	Wave/Z RadWave=$RadWavename
	Wave/Z GradWave=$GradWavename
	Wave/Z VecLengthWave=$VecLengthWavename
	Wave/Z RadWaveHIST=$RadWavenameHIST
	Wave/Z GradWaveHIST=$GradWavenameHIST
	Wave/Z VecLengthWaveHIST=$VecLengthWavenameHIST

	Wave/Z RadWaveAV=$RadWaveAVname
	Wave/Z GradWaveAV=$GradWaveAVname
	Wave/Z VecLengthWaveAV=$VecLengthWaveAVname
	Wave/Z RadWaveAVHIST=$RadWaveAVnameHIST
	Wave/Z GradWaveAVHIST=$GradWaveAVnameHIST
	Wave/Z VecLengthWaveAVHIST=$VecLengthWaveAVnameHIST

//------------------------------------------- down to here was consumed merely for naming the waves

	CalculateAngleAbsoluteSimple(VecLengthWave,VX,VY,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)
	CalculateAngleAbsoluteSimple(VecLengthWaveAV,VXav,VYav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)	
//	VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//	GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)

END


Function CalculateAngleAbsoluteSimple(L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST)
	Wave L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST

	variable L_Speed_Threshold=0 //021228
	Duplicate L_VX tempnull,tempVX
	Duplicate L_VY tempVY
	tempnull[][]=0
	//print "Angle Coordinate: absolute"
	tempVX[][]=((tempVX[p][q]==Nan) ? (0) : (tempVX[p][q]) )
	tempVY[][]=((tempVY[p][q]==Nan) ? (0) : (tempVY[p][q]) )
	L_VecLengthWave[][]=(sqroot(tempnull[p][q],tempnull[p][q],tempVX[p][q],tempVY[p][q]))
	L_VecLengthWave[][]=((numtype(L_VecLengthWave[p][q]) == 1) ? NaN :(L_VecLengthWave[p][q]))			//* delete inf
	L_RadWave[][]=((L_VecLengthWave[p][q]>L_speed_threshold) ? (acos((tempVY[p][q])/L_VeclengthWave[p][q])) : (Nan))
	L_RadWave[][]=((L_VX[p][q] >0) ? (2*pi-L_RadWave[p][q]) : L_RadWave[p][q]) 
	L_GradWave[][]=((L_Radwave[p][q]!=Nan) ? (L_RadWave[p][q]/2/3.1415*360): (Nan))
	//below is for the thresholding
	L_VecLengthWave[][]=(((L_VecLengthWave[p][q]>L_speed_threshold) && (L_VecLengthWave[p][q]!=inf)) ? (L_VecLengthWave[p][q]) : (NaN))
		
	killwaves tempnull,tempVX,tempVY
END

Function	initializeStatWaves(intensity,direction,dotsize)
	variable intensity,direction,dotsize
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)
	string VMstatwavename="VelMean"+suffix
	string VSstatwavename="VelSd"+suffix
	string GMstatwavename="GraMean"+suffix
	string GSstatwavename="GraSd"+suffix

	string VMavstatwavename="VelavMean"+suffix
	string VSavstatwavename="VelavSd"+suffix
	string GMavstatwavename="GraavMean"+suffix
	string GSavstatwavename="GraavSd"+suffix
	
	//setdatafolder root:
	Make/o/n=50 $VMstatwavename,$VSstatwavename,$GMstatwavename,$GSstatwavename
	Make/o/n=50 $VMavstatwavename,$VSavstatwavename,$GMavstatwavename,$GSavstatwavename

	wave/z VMstat=$VMstatwavename, VSstat=$VSstatwavename,GMstat=$GMstatwavename,GSstat=$GSstatwavename
	wave/z VMavstat=$VMavstatwavename, VSavstat=$VSavstatwavename,GMavstat=$GMavstatwavename,GSavstat=$GSavstatwavename

	Setscale/P x 0,0.2,"", VMstat,VSstat,GMstat,GSstat,VMavstat,VSavstat,GMavstat,GSavstat
END

//******* For Filtered
Function	initializeStatWavesFilt(intensity,direction,dotsize)
	variable intensity,direction,dotsize
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)
	string VMstatwavename="FVelMean"+suffix
	string VSstatwavename="FVelSd"+suffix
	string GMstatwavename="FGraMean"+suffix
	string GSstatwavename="FGraSd"+suffix

	string VMavstatwavename="FVelavMean"+suffix
	string VSavstatwavename="FVelavSd"+suffix
	string GMavstatwavename="FGraavMean"+suffix
	string GSavstatwavename="FGraavSd"+suffix
	
	//setdatafolder root:
	Make/o/n=50 $VMstatwavename,$VSstatwavename,$GMstatwavename,$GSstatwavename
	Make/o/n=50 $VMavstatwavename,$VSavstatwavename,$GMavstatwavename,$GSavstatwavename

	wave/z VMstat=$VMstatwavename, VSstat=$VSstatwavename,GMstat=$GMstatwavename,GSstat=$GSstatwavename
	wave/z VMavstat=$VMavstatwavename, VSavstat=$VSavstatwavename,GMavstat=$GMavstatwavename,GSavstat=$GSavstatwavename

	Setscale/P x 0,0.2,"", VMstat,VSstat,GMstat,GSstat,VMavstat,VSavstat,GMavstat,GSavstat
END
//**********************

Function V9_recordStats(VecLengthWave,GradWave,VelLoop,intensity,direction,dotsize)
	wave VecLengthWave,GradWave
	variable velloop,intensity,direction,dotsize
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)
	string VMstatwavename="root:VelMean"+suffix
	string VSstatwavename="root:VelSd"+suffix
	string GMstatwavename="root:GraMean"+suffix
	string GSstatwavename="root:GraSd"+suffix

	string VMavstatwavename="root:VelavMean"+suffix
	string VSavstatwavename="root:VelavSd"+suffix
	string GMavstatwavename="root:GraavMean"+suffix
	string GSavstatwavename="root:GraavSd"+suffix

	wave/z VM=$VMstatwavename,VS=$VSstatwavename,GM=$GMstatwavename,GS=$GSstatwavename
	wave/z VMav=$VMavstatwavename,VSav=$VSavstatwavename,GMav=$GMavstatwavename,GSav=$GSavstatwavename

	if (waveexists(VM))
		wave/z GradWave=$("deg")
		wave/z VecLengthWave=$("mag")
		wave/z GradWaveAV=$("degAV")
		wave/z VecLengthWaveAV=$("magAV")
		if (waveexists(VecLengthWave))
			wavestats/q VecLengthWave
			if (numtype(V_avg)==0)
				VM[VelLoop]=V_avg
				VS[VelLoop]=V_sdev
			else 
				VM[VelLoop]=0
				VS[VelLoop]=0
			endif
			//wavestats/q GradWave
			CircularStatistics2D(GradWave,2)
			NVAR/z X_bar
			NVAR/z delta_deg
			if (numtype(X_bar)==0)
				GM[VelLoop]=X_bar
				GS[VelLoop]=delta_deg
			else
				GM[VelLoop]=0
				GS[VelLoop]=0
			endif
			wavestats/q VecLengthWaveAV
			if (numtype(V_avg)==0)
				VMav[VelLoop]=V_avg
				VSav[VelLoop]=V_sdev
			else
				VMav[VelLoop]=0
				VSav[VelLoop]=0
			endif
			//wavestats/q GradWaveAV
			CircularStatistics2D(GradWaveAV,2)			
			if (numtype(X_bar)==0)
				GMav[VelLoop]=X_bar
				GSav[VelLoop]=delta_deg
			else
				GMav[VelLoop]=0
				GSav[VelLoop]=0
			endif
		else
			print "no vel wave"
		endif	
	else
		abort "generation of stat waves seems to be failed"
	endif
END

///*********** for filtered
Function V9_recordStatsFilt(VelLoop,intensity,direction,dotsize)
//	wave VecLengthWave,GradWave
	variable velloop,intensity,direction,dotsize
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)
	string VMstatwavename="root:FVelMean"+suffix
	string VSstatwavename="root:FVelSd"+suffix
	string GMstatwavename="root:FGraMean"+suffix
	string GSstatwavename="root:FGraSd"+suffix

	string VMavstatwavename="root:FVelavMean"+suffix
	string VSavstatwavename="root:FVelavSd"+suffix
	string GMavstatwavename="root:FGraavMean"+suffix
	string GSavstatwavename="root:FGraavSd"+suffix

	wave/z VM=$VMstatwavename,VS=$VSstatwavename,GM=$GMstatwavename,GS=$GSstatwavename
	wave/z VMav=$VMavstatwavename,VSav=$VSavstatwavename,GMav=$GMavstatwavename,GSav=$GSavstatwavename

	if (waveexists(VM))
		wave GradWave=$("degF")
		wave/z VecLengthWave=$("magF")
		wave/z GradWaveAV=$("degAVF")
		wave/z VecLengthWaveAV=$("magAVF")
		if (waveexists(VecLengthWave))
			wavestats/q VecLengthWave
			if (numtype(V_avg)==0)
				VM[VelLoop]=V_avg
				VS[VelLoop]=V_sdev
			else 
				VM[VelLoop]=0
				VS[VelLoop]=0
			endif
			//wavestats/q GradWave
			CircularStatistics2D(GradWave,2)
			NVAR/z X_bar
			NVAR/z delta_deg			
			if (numtype(X_bar)==0)
				GM[VelLoop]=X_bar
				GS[VelLoop]=delta_deg
			else
				GM[VelLoop]=0
				GS[VelLoop]=0
			endif
			wavestats/q VecLengthWaveAV
			if (numtype(V_avg)==0)
				VMav[VelLoop]=V_avg
				VSav[VelLoop]=V_sdev
			else
				VMav[VelLoop]=0
				VSav[VelLoop]=0
			endif
			wavestats/q GradWaveAV
			CircularStatistics2D(GradWaveAV,2)			
			if (numtype(X_bar)==0)
				GMav[VelLoop]=X_bar
				GSav[VelLoop]=delta_deg
			else
				GMav[VelLoop]=0
				GSav[VelLoop]=0
			endif
		else
			print "no vel wave"
		endif	
	else
		abort "generation of stat waves seems to be failed"
	endif
END

//************:the main routine
//		this function only loops for dotsize and velocity. 
Function V9_BatchVectorFieldAnalysis(intensity,direction,L_unit,frames,pathname)
	variable	intensity,direction,L_unit,frames
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6
	variable importflag=0
	variable i,j,k
	for (i=0; i<category_dotsize; i+=1)
		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(i))
		
		for (j=0; j<category_velocity; j+=1)
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(i),(j*2))		//j*2 to j*3 040818 //j*3 to j*2 041129

			do
				 importflag=V9_LoadSpecifiedStack(pathname,filename)
			while (importflag==0)			
//				newfilename=RenameTiffToMAT()
			newfilename=RenameTiffToMATNew(filename)	//030110
			wave/z matrix3D=$newfilename
			//Foldername=V9_singleVecField(matrix3D,L_unit,frames)
			V9_singleVecField(matrix3D,L_unit,frames)
			wave/z VecLengthWave,GradWave
			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(i))
			//setdatafolder root:
			killwaves matrix3D
			//killdatafolder $foldername
			//for (k=0;k<200000;K+=1)
			//endfor
		endfor
		
//		for  (j=0; j<category_velocity; j+=1)
//			V9_kill3DMatrix(intensity,direction,V9_dotsizeCorrection(i),(j*2))
//		endfor
		saveexperiment
	endfor
	
END

//same above but no loops for dotsize
Function V9_BatchVectorFieldAnalysis2(intensity,direction,dotsize,L_unit,frames,pathname)
	variable	intensity,direction,dotsize,L_unit,frames
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6
	variable i,j,k
	String current3D="MATc3D"
//	for (i=0; i<category_dotsize; i+=1)
		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(dotsize))
		
		for (j=0; j<category_velocity; j+=1)
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(dotsize),(j*2))
			if ( V9_LoadSpecifiedStack(pathname,filename)==0)
				continue					// new 030110
			endif
//			newfilename=RenameTiffToMAT()
			newfilename=RenameTiffToMATNew(filename)	//030110
			wave/z matrix3D=$newfilename
			Duplicate/O matrix3D $current3D
			wave/z MATcurrent3D=$current3D
			//Foldername=V9_singleVecField(matrix3D,L_unit,frames)
			//V9_singleVecField(matrix3D,L_unit,frames)
			V9_singleVecField(MATcurrent3D,L_unit,frames)
			wave/z VecLengthWave,GradWave
			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(dotsize))
			//saveexperiment
			//setdatafolder root:
			//killwaves matrix3D
			//killdatafolder $foldername
			//for (k=0;k<200000;K+=1)
			//endfor
		endfor
		
		for  (j=0; j<category_velocity; j+=1)
			V9_kill3DMatrix(intensity,direction,V9_dotsizeCorrection(dotsize),(j*2))
		endfor
		saveexperiment
//	endfor
	
END

Function V9_singleVectorFieldAnalysis(intensity,direction,dotsize,velocity,frames,pathname)
	variable	intensity,direction,dotsize,velocity,frames
	string pathname
	variable L_unit=3
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6
	variable i,j,k
	String current3D="MATc3D"
//	for (i=0; i<category_dotsize; i+=1)
//		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(dotsize))
		
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(dotsize),velocity)
			if ( V9_LoadSpecifiedStack(pathname,filename)==0)
				abort "no such a file"					// new 030110
			endif
			newfilename=RenameTiffToMATNew(filename)	//030110
			wave/z matrix3D=$newfilename
			Duplicate/O matrix3D $current3D
			wave/z MATcurrent3D=$current3D
			//Foldername=V9_singleVecField(matrix3D,L_unit,frames)
			//V9_singleVecField(matrix3D,L_unit,frames)
			V9_singleVecField(MATcurrent3D,L_unit,frames)
//			wave/z VecLengthWave,GradWave
//			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(dotsize))
			wave/z GradWave=$("deg")
			wave/z VecLengthWave=$("mag")
//			wave/z GradWaveAV=$("degAV")
//			wave/z VecLengthWaveAV=$("magAV")
//			if (waveexists(VecLengthWave))
				wavestats/q VecLengthWave
//				if (numtype(V_avg)==0)
					printf "average speed: %g\r", V_avg
					//VS[VelLoop]=V_sdev
//				endif
				wavestats/q GradWave
//				if (numtype(V_avg)==0)
					printf "average direction: %g\r"V_avg
					//GS[VelLoop]=V_sdev
//				endif
//				wavestats/q VecLengthWaveAV
//				if (numtype(V_avg)==0)
//					VMav[VelLoop]=V_avg
//					VSav[VelLoop]=V_sdev
//				endif
//				wavestats/q GradWaveAV
//				if (numtype(V_avg)==0)
//					GMav[VelLoop]=V_avg
//					GSav[VelLoop]=V_sdev
//				endif
			//else
			//	print "no vel wave"
			//endif	
			killwaves matrix3D
		
	
END

//** 030114 with filtering
Function V9_BatVFAnalFilt(intensity,direction,L_unit,frames,pathname,IntMin,IntMax)
	variable	intensity,direction,L_unit,frames,IntMin,IntMax
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6

	NVAR/z G_IntMin,G_IntMax
	if (NVAR_exists(G_IntMin)==0)
		Variable/G G_IntMin=IntMin
		Variable/G G_intMax=IntMax
	else
		G_IntMin=IntMin
		G_intMax=IntMax
	endif
			
	variable i,j,k
	for (i=0; i<category_dotsize; i+=1)
		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(i))
		initializeStatWavesFilt(intensity,direction,V9_dotsizeCorrection(i))
		for (j=0; j<category_velocity; j+=1)
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(i),(j*2))
			V9_LoadSpecifiedStack(pathname,filename)
			newfilename=RenameTiffToMATNew(filename)	//030110			
			wave/z matrix3D=$newfilename
			V9_singleVecField(matrix3D,L_unit,frames)
			wave/z VecLengthWave,GradWave
			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(i))
			//setdatafolder root:
			FilteredVecFieldDerive()
			 V9_recordStatsFilt(j,intensity,direction,V9_dotsizeCorrection(i))			
			killwaves matrix3D
		endfor
		
		saveexperiment
	endfor
	
END

Function V9_batAnalysis(intensity,L_unit,frames,pathname,IntMin,IntMax)		
	variable intensity,L_unit,frames,IntMin,IntMax
	string pathname
	variable direction
	variable i
//	for (i=0;i<5;i+=1)
	for (i=0;i<3;i+=1)		//030218 modification made for doing only 0, 30 and 45 degrees. Omit 70 and 90 degrees
		direction=V9_returnAngles(i)
		V9_BatVFAnalFilt(intensity,direction,L_unit,frames,pathname,IntMin,IntMax)
	endfor
END


//*******************************************************************************************
//test above filtered by just one wave
Function V9_BatVFAnalFiltTest(intensity,direction,dotsize,dotspeed,L_unit,frames,pathname,IntMin,IntMax)
	variable	intensity,direction,dotsize,dotspeed,L_unit,frames,IntMin,IntMax
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
//	variable category_dotsize=6

	NVAR/z G_IntMin,G_IntMax
	if (NVAR_exists(G_IntMin)==0)
		Variable/G G_IntMin=IntMin
		Variable/G G_intMax=IntMax
	else
		G_IntMin=IntMin
		G_intMax=IntMax
	endif
			
	variable i,j
//	for (i=0; i<category_dotsize; i+=1)
	i=dotsize
		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(i))
		initializeStatWavesFilt(intensity,direction,V9_dotsizeCorrection(i))
		//for (j=0; j<category_velocity; j+=1)
		j=dotspeed*10/2
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(i),(j*2))
			V9_LoadSpecifiedStack(pathname,filename)
			newfilename=RenameTiffToMATNew(filename)	//030110			
			wave/z matrix3D=$newfilename
			V9_singleVecField(matrix3D,L_unit,frames)
			wave/z VecLengthWave,GradWave
			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(i))
			//setdatafolder root:
			FilteredVecFieldDerive()
			 V9_recordStatsFilt(j,intensity,direction,V9_dotsizeCorrection(i))			
			killwaves matrix3D
		//endfor
		
		saveexperiment
//	endfor
	
END

Function V9_DisplayGraphs(intensity,direction)
	variable intensity,direction
	variable velloop,dotsize
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string VMavstatwavename,VSavstatwavename,GMavstatwavename,GSavstatwavename
	
	string windowsuffix="I"+num2str(intensity)+"D"+num2Str(direction)
	variable i
	for (i=0;i<6;i+=1)
		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		VMstatwavename="root:VelMean"+suffix
		VSstatwavename="root:VelSd"+suffix
		GMstatwavename="root:GraMean"+suffix
		GSstatwavename="root:GraSd"+suffix

		VMavstatwavename="root:VelavMean"+suffix
		VSavstatwavename="root:VelavSd"+suffix
		GMavstatwavename="root:GraavMean"+suffix
		GSavstatwavename="root:GraavSd"+suffix
		if (i==0)
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			dowindow/c $(windowsuffix+"_velocity")
			display $GMstatwavename
			ModifyGraph grid(left)=1
			dowindow/c $(windowsuffix+"_direction")
		else
			//dowindow/f $(windowsuffix+"_velocity")
			wave/z tempV=$VMstatwavename
			if (waveexists(tempV))
				AppendToGraph/w=$(windowsuffix+"_velocity") $VMstatwavename
			endif
			//dowindow/f $(windowsuffix+"_direction")
			wave/z tempG=$GMstatwavename
			if (waveexists(tempG))
				AppendToGraph/w=$(windowsuffix+"_direction") $GMstatwavename
			endif
		endif
	endfor
	
END

Function V9_DisplayAVGraphs(intensity,direction)
	variable intensity,direction
	variable velloop,dotsize
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string VMavstatwavename,VSavstatwavename,GMavstatwavename,GSavstatwavename
	
	string windowsuffix="AVI"+num2str(intensity)+"D"+num2Str(direction)
	variable i
	for (i=0;i<6;i+=1)
		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		VMstatwavename="root:VelMean"+suffix
		VSstatwavename="root:VelSd"+suffix
		GMstatwavename="root:GraMean"+suffix
		GSstatwavename="root:GraSd"+suffix

		VMavstatwavename="root:VelavMean"+suffix
		VSavstatwavename="root:VelavSd"+suffix
		GMavstatwavename="root:GraavMean"+suffix
		GSavstatwavename="root:GraavSd"+suffix
		if (i==0)
			display $VMavstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			dowindow/c $(windowsuffix+"_velocity")
			display $GMavstatwavename
			ModifyGraph grid(left)=1
			dowindow/c $(windowsuffix+"_direction")
		else
			//dowindow/f $(windowsuffix+"_velocity")
			wave/z tempV=$VMavstatwavename
			if (waveexists(tempV))
				AppendToGraph/w=$(windowsuffix+"_velocity") $VMavstatwavename
			endif
			//dowindow/f $(windowsuffix+"_direction")
			wave/z tempG=$GMavstatwavename
			if (waveexists(tempG))
				AppendToGraph/w=$(windowsuffix+"_direction") $GMavstatwavename
			endif
		endif
	endfor
	
END

Function V9_DisplayGraphsDirectionality(intensity,direction,size)		//this goes until Layout formation.
	variable intensity,direction,size
	variable velloop,dotsize
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string VMavstatwavename,VSavstatwavename,GMavstatwavename,GSavstatwavename
	variable i
//	for (i=0;i<6;i+=1)
	i=size	
	string windowsuffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))

		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix

		VMavstatwavename="VelavMean"+suffix
		VSavstatwavename="VelavSd"+suffix
		GMavstatwavename="GraavMean"+suffix
		GSavstatwavename="GraavSd"+suffix

		string VMstatFwavename="FVelMean"+suffix
		string VSstatFwavename="FVelSd"+suffix
		string GMstatFwavename="FGraMean"+suffix
		string GSstatFwavename="FGraSd"+suffix

		string VMavstatFwavename="FVelavMean"+suffix
		string VSavstatFwavename="FVelavSd"+suffix
		string GMavstatFwavename="FGraavMean"+suffix
		string GSavstatFwavename="FGraavSd"+suffix
			
//		if (i==0)
			//speed graph
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			Label left "Measured Speed [pix/frame]"
			Label bottom "speed [pix/frame]"			
			dowindow/c $(windowsuffix+"_velocity")
			wave/z tempV=$VMstatwavename
			if (waveexists(tempV))
				AppendToGraph/w=$(windowsuffix+"_velocity") $VMavstatwavename
				AppendToGraph/w=$(windowsuffix+"_velocity") $VMstatFwavename
				AppendToGraph/w=$(windowsuffix+"_velocity") $VMavstatFwavename
			endif
			ModifyGraph mode($VMavstatwavename)=3,rgb($VMstatFwavename)=(16384,28160,65280)
			ModifyGraph mode($VMavstatFwavename)=3,marker($VMavstatFwavename)=8
			ModifyGraph rgb($VMavstatFwavename)=(16384,28160,65280)			
			Legend/C/N=text0/J/A=MC ("\\Z07\\s("+VMstatwavename+") Original\r\\s("+VMavstatwavename+") Averaged\r\\s("+VMstatFwavename+") Original-Int filtered\r\\s("+VMavstatFwavename+") Averaged-Int filtered")
			TextBox/C/N=text1/A=MC ("\\Z07Intensity "+num2str(intensity)+"\rDirection "+num2str(direction+270)+"\rDotsize "+num2Str(V9_dotsizeCorrection(i)))
			TextBox/C/N=text0/A=RT/X=0/Y=0
			TextBox/C/N=text1/A=RC/X=0/Y=0

			//angle graph
			display
			AppendTograph/L=originalAxis/B=speedAxis  $GMstatwavename
			Label originalAxis "Direction [degrees]"
			Label speedAxis "speed [pix/frame]"
			dowindow/c $(windowsuffix+"_direction")
			ModifyGraph grid(originalAxis)=1
			wave/z tempG=$GMstatwavename
			if (waveexists(tempG))
				AppendToGraph/w=$(windowsuffix+"_direction")/L=originalAxis/B=speedAxis $GMavstatwavename
				AppendToGraph/w=$(windowsuffix+"_direction")/L=originalAxis/B=speedAxis $GMstatFwavename
				AppendToGraph/w=$(windowsuffix+"_direction")/L=originalAxis/B=speedAxis $GMavstatFwavename
			endif		
			ModifyGraph mode($GMavstatwavename)=3,rgb($GMstatFwavename)=(16384,28160,65280)
			ModifyGraph mode($GMavstatFwavename)=3,marker($GMavstatFwavename)=8
			ModifyGraph rgb($GMavstatFwavename)=(16384,28160,65280)			
			string GMstatDeltawavename=GMstatwavename+"Del"
			Duplicate/o $GMstatwavename,$GMstatDeltawavename
			wave/z delta=$GMstatDeltawavename
			delta=delta-(270+direction)
			delta[]=(delta[p]>180 ? delta[p]-360 : delta[p])
			delta[]=(delta[p]<-180 ? delta[p]+360 : delta[p])
			delta[0]=0
			AppendToGraph/w=$(windowsuffix+"_direction")/L=deltaAxis/B=speedAxis $GMstatDeltawavename
			ModifyGraph axisEnab(originalAxis)={0,0.75}
			ModifyGraph axisEnab(deltaAxis)={0.85,1}
			ModifyGraph margin(left)=80,margin(bottom)=50
			ModifyGraph freePos(originalAxis)=10
			ModifyGraph freePos(deltaAxis)=10
			ModifyGraph freePos(speedAxis)=12			
			ModifyGraph zero(deltaAxis)=1
			ModifyGraph lblPos(originalAxis)=50,lblLatPos(originalAxis)=8
			ModifyGraph lblPos(deltaAxis)=50,lblLatPos(originalAxis)=8
			ModifyGraph lblPos(speedAxis)=35
			SetAxis deltaAxis -45,45 			
			Label deltaAxis "delta [degrees]"
			ModifyGraph lblPos(deltaAxis)=50,lblLatPos(deltaAxis)=8
			ModifyGraph grid(speedAxis)=2
			
			string GMavstatDeltawavename=GMavstatwavename+"Del"
			string GMstatFDeltawavename=GMstatFwavename+"Del"
			string GMavstatFDeltawavename=GMavstatFwavename+"Del"
			Duplicate/o $GMavstatwavename,$GMavstatDeltawavename
			Duplicate/o $GMstatFwavename,$GMstatFDeltawavename
			Duplicate/o $GMavstatFwavename,$GMavstatFDeltawavename
			wave/z deltaAV=$GMavstatDeltawavename
			wave/z deltaF=$GMstatFDeltawavename
			wave/z deltaFAV=$GMavstatFDeltawavename
			deltaAV=deltaAV-(270+direction)
			delta[]=(deltaAV[p]>180 ? deltaAV[p]-360 : deltaAV[p])
			delta[]=(deltaAV[p]<-180 ? deltaAV[p]+360 : deltaAV[p])

			deltaF=deltaF-(270+direction)
			deltaF[]=(deltaF[p]>180 ? deltaF[p]-360 : deltaF[p])
			deltaF[]=(deltaF[p]<-180 ? deltaF[p]+360 : deltaF[p])

			deltaFAV=deltaFAV-(270+direction)
			deltaFAV[]=(deltaFAV[p]>180 ? deltaFAV[p]-360 : deltaFAV[p])
			deltaFAV[]=(deltaFAV[p]<-180 ? deltaFAV[p]+360 : deltaFAV[p])

			deltaAV[0]=0
			deltaF[0]=0
			deltaFAV[0]=0

			AppendToGraph/w=$(windowsuffix+"_direction")/L=deltaAxis/B=speedAxis $GMavstatDeltawavename
			AppendToGraph/w=$(windowsuffix+"_direction")/L=deltaAxis/B=speedAxis $GMstatFDeltawavename
			AppendToGraph/w=$(windowsuffix+"_direction")/L=deltaAxis/B=speedAxis $GMavstatFDeltawavename
			ModifyGraph mode($GMavstatDeltawavename)=3,rgb($GMstatFDeltawavename)=(16384,28160,65280)
			ModifyGraph mode($GMavstatFDeltawavename)=3,marker($GMavstatFDeltawavename)=8
			ModifyGraph rgb($GMavstatFDeltawavename)=(16384,28160,65280)		
			Legend/C/N=text0/J/A=MC ("\\Z07\\s("+GMstatwavename+") Original\r\\s("+GMavstatwavename+") Averaged\r\\s("+GMstatFwavename+") Original-Int filtered\r\\s("+GMavstatFwavename+") Averaged-Int filtered")
			TextBox/C/N=text1/A=MC ("\\Z07Intensity "+num2str(intensity)+"\rDirection "+num2str(direction+270)+"\rDotsize "+num2Str(V9_dotsizeCorrection(i)))
			TextBox/C/N=text0/A=RT/X=0/Y=0
			TextBox/C/N=text1/A=RC/X=0/Y=0
			
			NewLayout/C=1 
			AppendLayoutObject/F=0 graph $(windowsuffix+"_direction")
			AppendLayoutObject/F=0 graph $(windowsuffix+"_velocity")
			TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
			ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
			TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
			ModifyLayout units=0;
			ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
END


function V9_differentDotSize(intensity,direction)		//030217
	variable intensity,direction
	variable size
	variable velloop,dotsize
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	variable i
	for (i=0;i<6;i+=1)
		//i=size	
		string windowsuffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"//+num2Str(V9_dotsizeCorrection(i))
		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix
		//speed graph
		if (i==0)
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			Label left "Measured Speed [pix/frame]"
			Label bottom "speed [pix/frame]"			
			dowindow/c $(windowsuffix+"_velocity")
			TextBox/C/N=text1/A=MC ("\\Z07Intensity "+num2str(intensity)+"\rDirection "+num2str(direction+270) ) //+"\rDotsize "+num2Str(V9_dotsizeCorrection(i)))
			TextBox/C/N=text1/A=RC/X=0/Y=0			
		else
			dowindow/F $(windowsuffix+"_velocity")		
			AppendToGraph/w=$(windowsuffix+"_velocity") $VMstatwavename
		endif	
		Tag/N=$("text"+num2str(i+2)) $VMstatwavename,(1+i*1.8),("dot"+num2Str(V9_dotsizeCorrection(i)))

		//angle graph
		if (i==0)
			display $GMstatwavename
			//AppendTograph/L=originalAxis/B=speedAxis  $GMstatwavename
			Label left "Direction [degrees]"
			Label bottom "speed [pix/frame]"
			ModifyGraph grid(bottom)=1,tick(bottom)=2
			ModifyGraph nticks(bottom)=15
			dowindow/c $(windowsuffix+"_direction")
			//ModifyGraph grid=1
			TextBox/C/N=text1/A=MC ("\\Z07Intensity "+num2str(intensity)+"\rDirection "+num2str(direction+270))//+"\rDotsize "+num2Str(V9_dotsizeCorrection(i)))
			//TextBox/C/N=text0/A=RT/X=0/Y=0
			TextBox/C/N=text1/A=RC/X=0/Y=0
//			Legend/C/N=text0/J ("\\Z08\\s dot "+num2Str(V9_dotsizeCorrection(i)))
		else
			dowindow/F $(windowsuffix+"_direction")
			AppendToGraph/w=$(windowsuffix+"_direction") $GMstatwavename
//			AppendText/N=text0 ("\\s dot "+num2Str(V9_dotsizeCorrection(i)))
		endif
		Tag/N=$("text"+num2str(i+2)) $GMstatwavename, (1+i*1.8),("dot"+num2Str(V9_dotsizeCorrection(i)))
	endfor
			NewLayout/C=1 
			AppendLayoutObject/F=0 graph $(windowsuffix+"_direction")
			AppendLayoutObject/F=0 graph $(windowsuffix+"_velocity")
			TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
			ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
			TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
			ModifyLayout units=0;
			ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60


END


function V9_differentIntensity(direction,dotsize)		//030217 -2
	variable direction,dotsize
	variable intensity,size
	variable velloop
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	variable i
	for (i=0;i<6;i+=1)
		//i=size	
		intensity=V9_returnIntensities(i)
		size=V9_dotsizeCorrection(dotsize)
//		string windowsuffix="I"+num2str(V9_returnIntensities(i))+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		string windowsuffix="D"+num2Str(direction)+"S"+num2Str(size)
		string win_vel=windowsuffix+"_velocity"
		string win_dir=windowsuffix+"_direction"

		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix
		//speed graph
		if (i==0)
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			Label left "Measured Speed [pix/frame]"
			Label bottom "speed [pix/frame]"			
			dowindow/c $win_vel
			TextBox/C/N=text1/A=MC ("\\Z07Direction "+num2str(direction+270)+"\rDotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0			
			dowindow/F $(win_vel)	
		else
			dowindow/F $(win_vel)		
			AppendToGraph/w=$(win_vel) $VMstatwavename
		endif	
		Tag/w=$win_vel/N=$("text"+num2str(i+2)) $VMstatwavename,(1+i*1.8),("Int"+num2Str(intensity))

		//angle graph
		if (i==0)
			display $GMstatwavename
			//AppendTograph/L=originalAxis/B=speedAxis  $GMstatwavename
			Label left "Direction [degrees]"
			Label bottom "speed [pix/frame]"
			ModifyGraph grid(bottom)=1,tick(bottom)=2
			ModifyGraph nticks(bottom)=15
			dowindow/c $(windowsuffix+"_direction")
			TextBox/C/N=text1/A=MC ("\\Z07Direction "+num2str(direction+270)+"\rDotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0
		else
			dowindow/F $(windowsuffix+"_direction")
			AppendToGraph/w=$(windowsuffix+"_direction") $GMstatwavename
		endif
		Tag/N=$("text"+num2str(i+2)) $GMstatwavename, (1+i*1.8),("Int"+num2Str(intensity))
	endfor
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(windowsuffix+"_direction")
	AppendLayoutObject/F=0 graph $(windowsuffix+"_velocity")
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Direction: "+num2str(direction+270)+"\rDot Size: "+num2str(V9_dotsizeCorrection(dotsize))	
	ModifyLayout units=0;
	ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=99.75
	ModifyLayout top($(win_vel))=170.25
	ModifyLayout left($(win_dir))=99.75
	ModifyLayout top($(win_dir))=450
END

function V9_differentIntensityALL(dotsize)		//030217 -3
	variable dotsize
	variable direction,intensity,size
	variable velloop
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	variable i,j
	for (j=0;j<3;j+=1)
	direction= V9_returnAngles(j)
	for (i=0;i<6;i+=1)
		//i=size	
		intensity=V9_returnIntensities(i)
		size=V9_dotsizeCorrection(dotsize)
//		string windowsuffix="I"+num2str(V9_returnIntensities(i))+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
//		string windowsuffix="D"+num2Str(direction)+"S"+num2Str(size)
		string windowsuffix="S"+num2Str(size)
		string win_vel=windowsuffix+"_velocity"
		string win_dir=windowsuffix+"_direction"

		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix

		VMstatwavename="F"+VMstatwavename		// 030224 for noise added
		VSstatwavename="F"+VSstatwavename		// 030224 for noise added
		GMstatwavename="F"+GMstatwavename		// 030224 for noise added
		GSstatwavename="F"+GSstatwavename		// 030224 for noise added
				
		//speed graph
		if (i==0&&j==0)
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			Label left "Measured Speed [pix/frame]"
			Label bottom "speed [pix/frame]"			
			dowindow/c $win_vel
			TextBox/C/N=text1/A=MC ("\\Z07Dotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0			
			dowindow/F $(win_vel)	
		else
			dowindow/F $(win_vel)		
			AppendToGraph/w=$(win_vel) $VMstatwavename
		endif	
		Tag/w=$win_vel/N=$("textD"+num2str(direction)+num2str(i+2)) $VMstatwavename,(1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))

		//angle graph
		if (i==0&&j==0)
			display $GMstatwavename
			//AppendTograph/L=originalAxis/B=speedAxis  $GMstatwavename
			Label left "Direction [degrees]"
			Label bottom "speed [pix/frame]"
			ModifyGraph grid(bottom)=1,tick(bottom)=2
			ModifyGraph nticks(bottom)=15
			dowindow/c $(windowsuffix+"_direction")
			TextBox/C/N=text1/A=MC ("\\Z07Dotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0
		else
			dowindow/F $(windowsuffix+"_direction")
			AppendToGraph/w=$(windowsuffix+"_direction") $GMstatwavename
		endif
		Tag/N=$("textD"+num2str(direction)+num2str(i+2)) $GMstatwavename, (1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))
	endfor
	endfor
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(windowsuffix+"_direction")
	AppendLayoutObject/F=0 graph $(windowsuffix+"_velocity")
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Direction: "+num2str(direction+270)+"\rDot Size: "+num2str(V9_dotsizeCorrection(dotsize))	
	ModifyLayout units=0;
	ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=99.75
	ModifyLayout top($(win_vel))=170.25
	ModifyLayout left($(win_dir))=99.75
	ModifyLayout top($(win_dir))=450
END




//******* for summarizing 030212 ~

function AbsoluteSum(srcwave1D)
	wave srcwave1D
	variable i,abssum
	abssum=0
	for (i=0;i<numpnts(srcwave1D);i+=1)
		abssum+=abs(srcwave1D[i])
	endfor
	return abssum
end

function FindMinPoint(srcwave)
	wave srcwave
	variable i,count
	count=0
	for (i=0;i<numpnts(srcwave);i+=1)
		if (srcwave[i]==0)
			count+=1
		else
		 	break
		endif
	endfor
	return count
end

Function FindMaxPoint(srcwave)
	wave srcwave
	variable i,count
	count=numpnts(srcwave)
	for (i=numpnts(srcwave);i>0;i-=1)
		if (srcwave[i]==0)
			count-=1
		else
		 	break
		endif
	endfor
	return count
end

Function FindMaxPoint_firstband(srcwave)
	wave srcwave
	variable i,count,countBand
	count=0
	countBand=0
	for (i=0;i<numpnts(srcwave);i+=1)
		if ((countBand==1) && (srcwave[i]==0))
			break
		endif
		if (srcwave[i]==1)
			countBand=1
		endif
		count+=1
	endfor
	return count-1
end

function FindRangeInErrorDirection(srcwave,direction,range)
	wave srcwave
	variable direction,range
	variable x_scale
	x_scale=0.2
	NVAR/z range_min,range_max
	if (NVAR_exists(range_min)==0)
		Variable/G range_min
		Variable/G range_max
	endif
	if (direction>=360)
		direction=direction-360
		printf "direction collected %f\r",direction
	endif
	variable Direction_min,Direction_max
	Direction_min=Direction-range
	if (Direction_min<0)
		Direction_min=360+direction_min
		printf "minimum range collected %f\r",direction_min
	endif
	Direction_max=Direction+range
	if (direction_max>=360)
		direction_max=direction_max-360
		printf "maximum range collected %f\r",direction_max
	endif
		
	Make/O/N=(numpnts(srcwave)) tempDetermine
	Make/O/N=(numpnts(srcwave)-1) tempDetermin2	
	wave/z tempDetermine,tempDetermin2
//		tempDetermine[]=( (((Direction-range) < srcwave[p]) && ((Direction+range) > srcwave[p])) ? 1 : 0)
	
	if (Direction_max>Direction_min)
		tempDetermine[]=( (((Direction_min) < srcwave[p]) && ((Direction_max) > srcwave[p])) ? 1 : 0)
	else
		tempDetermine[]=( ((((Direction_min) < srcwave[p]) && ((360) > srcwave[p]) ) || ( ((Direction_max) > srcwave[p]) && (0 <= srcwave[p]) )) ? 1 : 0)
		print "special case applied"
	endif
	tempDetermin2[]=tempDetermine[p]-tempDetermine[p+1]
	variable abssum=0
	abssum=AbsoluteSum(tempDetermin2)
	if ((abssum==2) || (abssum==1))	//only one range
		range_min=x_scale*FindMinPoint(tempDetermine)
		range_max=x_scale*FindMaxPoint(tempDetermine)
		//printf "Range min %f , max %f\r",range_min,range_max
		return range_min			
	else
		if (abssum==0)
			if (tempDetermine[0]==1)
				range_min=0
				range_max=x_scale*(numpnts(tempDetermine)-1)
				print "all range is possible"
			else
				printf "All points out of range for %s\r",nameofwave(srcwave)
			endif
		else
			printf "multiple ranges: see the wave %s details\r",nameofwave(srcwave)
		endif
		return -1
	endif
	
end

function FindRangeInErrorVelocity(srcwave,range)	//in this case, ratio such as 0.1 or 0.05
	wave srcwave
	variable range
	variable x_scale
	x_scale=0.2
	NVAR/z range_min,range_max
	if (NVAR_exists(range_min)==0)
		Variable/G range_min
		Variable/G range_max
	endif
	Make/O/N=(numpnts(srcwave)) tempDetermine
	Make/O/N=(numpnts(srcwave)-1) tempDetermin2	
	wave/z tempDetermine,tempDetermin2
	tempDetermine[]=( (( (p*0.2*(1-range)) < srcwave[p]) && ((p*0.2*(1+range)) > srcwave[p])) ? 1 : 0)
	tempDetermin2[]=tempDetermine[p]-tempDetermine[p+1]
	variable abssum=0
	abssum=AbsoluteSum(tempDetermin2)
	if ((abssum==2) || (abssum==1))	//only one range
		range_min=x_scale*FindMinPoint(tempDetermine)
		range_max=x_scale*FindMaxPoint(tempDetermine)
		//printf "Range min %f , max %f\r",range_min,range_max
		return range_min			
	else
		if (abssum==0)
			printf "All points out of range for %s\r",nameofwave(srcwave)
		else
			//print "multiple ranges: first range calculated. Check the wave details"
			range_min=x_scale*FindMinPoint(tempDetermine)
			range_max=x_scale*FindMaxPoint_firstband(tempDetermine)
			//printf "Range min %f , max %f\r",range_min,range_max
			return range_min						
		endif
	endif
	
end

function FindRangeInErrorVelocity2(srcwave,range)	//in this case, absolute range
	wave srcwave
	variable range
	variable x_scale
	x_scale=0.2
	NVAR/z range_min,range_max
	if (NVAR_exists(range_min)==0)
		Variable/G range_min
		Variable/G range_max
	endif
	Make/O/N=(numpnts(srcwave)) tempDetermine
	Make/O/N=(numpnts(srcwave)-1) tempDetermin2	
	wave/z tempDetermine,tempDetermin2
	tempDetermine[]=( (( (p*0.2-range) < srcwave[p]) && ((p*0.2+range) > srcwave[p])) ? 1 : 0)
	tempDetermin2[]=tempDetermine[p]-tempDetermine[p+1]
	variable abssum=0
	abssum=AbsoluteSum(tempDetermin2)
	if ((abssum==2) || (abssum==1))	//only one range
		range_min=x_scale*FindMinPoint(tempDetermine)
		range_max=x_scale*FindMaxPoint(tempDetermine)
		//printf "Range min %f , max %f\r",range_min,range_max
		return range_min			
	else
		if (abssum==0)
			printf "All points out of range for %s\r",nameofwave(srcwave)
		else
			//print "multiple ranges: first range calculated. Check the wave details"
			range_min=x_scale*FindMinPoint(tempDetermine)
			range_max=x_scale*FindMaxPoint_firstband(tempDetermine)
			//printf "Range min %f , max %f\r",range_min,range_max
			return range_min						
		endif
	endif
	
end

Function DoAllDotSizeSameInt(intensity,direction,rangeV,rangeG)		//with different dot size 030212
	variable intensity,direction,rangeV,rangeG
	//variable dotsize
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
//	string VMavstatwavename,VSavstatwavename,GMavstatwavename,GSavstatwavename
	string suffix_d="I"+num2str(intensity)//+"D"+num2Str(direction)
		string DotSizeVSrangeVMINwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		string DotSizeVSrangeVMAXwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"
		string DotSizeVSrangeGMINwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		string DotSizeVSrangeGMAXwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"

		Make/O/N=6	$DotSizeVSrangeVMINwavename,$DotSizeVSrangeVMAXwavename
		Make/O/N=6	$DotSizeVSrangeGMINwavename,$DotSizeVSrangeGMAXwavename
		wave/z DotSizeVSrangeVMAXwave=$DotSizeVSrangeVMAXwavename
		wave/z DotSizeVSrangeVMINwave=$DotSizeVSrangeVMINwavename
		wave/z DotSizeVSrangeGMAXwave=$DotSizeVSrangeGMAXwavename
		wave/z DotSizeVSrangeGMINwave=$DotSizeVSrangeGMINwavename

	NVAR/z range_min,range_max
	variable i
	for (i=0;i<6;i+=1)
	//i=size	
		string windowsuffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix
		wave/z VMstatwave=$VMstatwavename
		wave/z GMstatwave=$GMstatwavename
		

		FindRangeInErrorVelocity(VMstatwave,rangeV)
		DotSizeVSrangeVMINwave[i]=range_min	
		DotSizeVSrangeVMAXwave[i]=range_max	
		FindRangeInErrorDirection(GMstatwave,(direction+270),rangeG)
		DotSizeVSrangeGMINwave[i]=range_min	
		DotSizeVSrangeGMAXwave[i]=range_max	
	endfor

	
////	Display DotSizeVSrangeVMINwave vs dotsize
////	Dowindow/C velocity_range
//////	appendtograph DotSizeVSrangeVMINwave vs dotsize
////	appendtograph DotSizeVSrangeVMAXwave vs dotsize
////	Display DotSizeVSrangeGMINwave vs dotsize
////	Dowindow/C direction_range
//////	appendtograph DotSizeVSrangeGMINwave vs dotsize
////	appendtograph DotSizeVSrangeGMAXwave vs dotsize

end

Function DoAllwithDifInt(direction,rangeV,rangeG)
	variable direction,rangeV,rangeG
	variable i

	
		string DotSizeVSrangeVMINwavename//="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		string DotSizeVSrangeVMAXwavename//="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"
		string DotSizeVSrangeGMINwavename//="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		string DotSizeVSrangeGMAXwavename//="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"

//		wave/z DotSizeVSrangeVMAXwave=$DotSizeVSrangeVMAXwavename
//		wave/z DotSizeVSrangeVMINwave=$DotSizeVSrangeVMINwavename
//		wave/z DotSizeVSrangeGMAXwave=$DotSizeVSrangeGMAXwavename
//		wave/z DotSizeVSrangeGMINwave=$DotSizeVSrangeGMINwavename	
	
	string velocity_range="velocity_range"+num2str(direction)
	string direction_range="direction_range"+num2str(direction)
	string suffix_d
	
	for (i=0;i<6;i+=1)
		DoAllDotSizeSameInt(V9_returnIntensities(i),direction,rangeV,rangeG)
		suffix_d="I"+num2str(V9_returnIntensities(i))//+"D"+num2Str(direction)		
		DotSizeVSrangeVMINwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		DotSizeVSrangeVMAXwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"
		DotSizeVSrangeGMINwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		DotSizeVSrangeGMAXwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"

		wave/z DotSizeVSrangeVMAXwave=$DotSizeVSrangeVMAXwavename
		wave/z DotSizeVSrangeVMINwave=$DotSizeVSrangeVMINwavename
		wave/z DotSizeVSrangeGMAXwave=$DotSizeVSrangeGMAXwavename
		wave/z DotSizeVSrangeGMINwave=$DotSizeVSrangeGMINwavename			
		DoWindow/f	$velocity_range
		if (V_flag==0)
			Display DotSizeVSrangeVMINwave vs dotsize
			Dowindow/C $velocity_range
			appendtograph DotSizeVSrangeVMAXwave vs dotsize
			Display DotSizeVSrangeGMINwave vs dotsize
			Dowindow/C $direction_range
			appendtograph DotSizeVSrangeGMAXwave vs dotsize
		else
			appendtograph DotSizeVSrangeVMINwave vs dotsize
			appendtograph DotSizeVSrangeVMAXwave vs dotsize
			Dowindow/F $direction_range
			appendtograph DotSizeVSrangeGMINwave vs dotsize
			appendtograph DotSizeVSrangeGMAXwave vs dotsize
		endif
		
//		if (i==0)
//
//	
//		else
//			Dowindow/F 
//		endif
		
	endfor
	
END

function ErrorRatioVel(srcwave)
	wave srcwave
	string errorwavename=NameOfwave(srcwave)+"_error"
	Make/O/N=(numpnts(srcwave)) $errorwavename
	wave/z errorwave=$errorwavename
	errorwave[]=srcwave[p]/0.2/p
end

Function SpecificFor360to0()		// coded for converting all 360 degrees to 0.
	string GRAlist=wavelist("Fgra*",";","")
	variable itemnum=itemsinlist(GRAlist)
	string current_wavename
	variable i
	for (i=0;i<itemnum;i+=1)
		current_wavename=stringfromlist(i,GRAlist)
		wave/z currentwave=$current_wavename
		currentwave[]=((currentwave[p]==360) ? 0 : currentwave[p]) 
	endfor
END

//***** get valid range by linear fitting 030217


Function V9_linearFitFindRange(srcwave,PrThres)
	wave srcwave
	variable Prthres
	variable i
	NVAR/z maxpnt
	if (NVAR_exists(maxpnt)==0)
		variable/G maxpnt
	endif
	make/O/N=50 testPr,testSlope
	 testPr=0
	 wave/z W_coef
	for (i=49;i>0;i-=1)
		CurveFit/Q/H="10" line srcwave[0,i] /D
		 testPr[i]=V_Pr
		 if (V_Pr>Prthres)
		 	maxpnt=i*0.2
		 	printf "range max=%f  ",maxpnt
		 	printf "slope = %f\r",(W_coef[1])
		 	break
		 endif
	endfor
	
END

Function V9_FindRangeFit(PrThres)
	variable PrThres
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string fitwavename,VMrangeMax,VMslopename
	variable size,direction,intensity
	variable i,j,k
//=0.97
	NVAR/z maxpnt
	for (k=0;k<6;k+=1)
		size=V9_dotsizeCorrection(k)
		for (j=0;j<3;j+=1)
			direction= V9_returnAngles(j)
			VMrangeMax="Vmax"+"D"+num2Str(direction)+"S"+num2Str(size)
			VMslopename="Vslope"+"D"+num2Str(direction)+"S"+num2Str(size)
			Make/O/N=6 $VMrangeMax,$VMslopename 
			wave/z VMrangeM=$VMrangeMax
			wave/z VMslope=$VMslopename
			for (i=0;i<6;i+=1)
				intensity=V9_returnIntensities(i)
				string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
				VMstatwavename="VelMean"+suffix
				VSstatwavename="VelSd"+suffix
				GMstatwavename="GraMean"+suffix
				GSstatwavename="GraSd"+suffix
				wave/z srcwave=$VMstatwavename
				fitwavename="fit_"+VMstatwavename
				Display $VMstatwavename
				Dowindow/c tempWin
				V9_linearFitFindRange(srcwave,PrThres)
				wave/z W_coef
				NVAR/z V_Pr
//				printf "2range max=%f\r",maxpnt
				VMrangeM[i]=maxpnt//V_Pr
				VMslope[i]=W_coef[1]
				wave/z fitwave=$fitwavename
				Dowindow/k tempWin
				killwaves/z $fitwavename
			endfor
			Dowindow/F Vrange
			if (V_flag==0)
				Display $VMrangeMax
				Dowindow/C Vrange
			else
				appendtograph/w=Vrange $VMrangeMax
			endif
			Dowindow/F Vslope
			if (V_flag==0)
				Display $VMslopename
				Dowindow/C Vslope
			else
				appendtograph/w=Vslope $VMslopename
			endif
		endfor
	endfor		
END


Function V9_FindRangeFit_summarize()		//030217			for making graphs (Vmax and Vslope range finding)
//	variable PrThres
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string fitwavename,VMrangeMax,VMslopename
	variable size,direction,intensity
	variable i,j,k
//=0.97
//	string VMrangeMaxAV00="Vmax"+"D0"
//	string VMrangeMaxAV30="Vmax"+"D30"
//	string VMrangeMaxAV45="Vmax"+"D45"
//	string VMrangeMaxAV00sd="Vmax"+"D0sd"
//	string VMrangeMaxAV30sd="Vmax"+"D30sd"
//	string VMrangeMaxAV45sd="Vmax"+"D45sd"
	string VMrangeMaxAV00="Vslope"+"D0"
	string VMrangeMaxAV30="Vslope"+"D30"
	string VMrangeMaxAV45="Vslope"+"D45"
	string VMrangeMaxAV00sd="Vslope"+"D0sd"
	string VMrangeMaxAV30sd="Vslope"+"D30sd"
	string VMrangeMaxAV45sd="Vslope"+"D45sd"

	Make/N=6 $VMrangeMaxAV00,$VMrangeMaxAV30,$VMrangeMaxAV45,$VMrangeMaxAV00sd,$VMrangeMaxAV30sd,$VMrangeMaxAV45sd
	wave/z VMmaxD00=$VMrangeMaxAV00,VMmaxD30=$VMrangeMaxAV30,VMmaxD45=$VMrangeMaxAV45
	wave/z VMmaxD00sd=$VMrangeMaxAV00sd,VMmaxD30sd=$VMrangeMaxAV30sd,VMmaxD45sd=$VMrangeMaxAV45sd
	
	NVAR/z maxpnt
	for (k=0;k<6;k+=1)
		size=V9_dotsizeCorrection(k)
		for (j=0;j<3;j+=1)
			direction= V9_returnAngles(j)
			VMrangeMax="Vmax"+"D"+num2Str(direction)+"S"+num2Str(size)
			VMslopename="Vslope"+"D"+num2Str(direction)+"S"+num2Str(size)
			Make/O/N=6 $VMrangeMax,$VMslopename 
			wave/z VMrangeM=$VMrangeMax
			wave/z VMslope=$VMslopename
//			wavestats/q VMrangeM
			wavestats/q VMslope
			switch(direction)	// numeric switch
				case 0:		// execute if case matches expression
					VMmaxD00[k]=V_avg
					VMmaxD00sd[k]=V_sdev
					break						// exit from switch
				case 30:		// execute if case matches expression
					VMmaxD30[k]=V_avg
					VMmaxD30sd[k]=V_sdev
					break						// exit from switch
				case 45:		// execute if case matches expression
					VMmaxD45[k]=V_avg
					VMmaxD45sd[k]=V_sdev
					break						// exit from switch
			endswitch
		endfor
	endfor
	Display $VMrangeMaxAV00,$ VMrangeMaxAV30,$ VMrangeMaxAV45 vs Dotsize
	ErrorBars $VMrangeMaxAV00 Y,wave=($VMrangeMaxAV00sd,$VMrangeMaxAV00sd)
	ErrorBars $VMrangeMaxAV30 Y,wave=($VMrangeMaxAV30sd,$VMrangeMaxAV30sd)
	ErrorBars $VMrangeMaxAV45 Y,wave=($VMrangeMaxAV45sd,$VMrangeMaxAV45sd)

		//SetAxis left 0,10 		
END


Function V9_FindRangeFitSpec(size,direction,intensity)  //singular mode of the above loop
	variable size,direction,intensity
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string fitwavename,VMrangeMax,VMslopename
	variable i,j,k
	variable PrThres=0.97
	NVAR/z maxpnt
				string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
				VMstatwavename="VelMean"+suffix
				VSstatwavename="VelSd"+suffix
				GMstatwavename="GraMean"+suffix
				GSstatwavename="GraSd"+suffix
				wave/z srcwave=$VMstatwavename
				fitwavename="fit_"+VMstatwavename
				Display $VMstatwavename
				//Dowindow/c tempWin
				V9_linearFitFindRange(srcwave,PrThres)
				wave/z W_coef
				NVAR/z V_Pr
				printf "range max=%f    ",maxpnt
				printf "Pr =%f    ",V_Pr
				printf "Slope= %f   \r",W_coef[1]
END

//-------------------------------


 

//====================================================================================
//not used anymore after IgorPro bug fixing 030113

Function V9_BatchVectorFieldAnalysis3(intensity,direction,dotsize,L_unit,frames,pathname)
	variable	intensity,direction,dotsize,L_unit,frames
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6
	variable i,j,k
	String current3D="MATc3D"
//	for (i=0; i<category_dotsize; i+=1)
		initializeStatWaves(intensity,direction,V9_dotsizeCorrection(dotsize))
		
		for (j=0; j<category_velocity; j+=1)
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(dotsize),(j*2))
			if ( V9_LoadSpecifiedStack(pathname,filename)==0)
				continue					// new 030110
			endif
//			newfilename=RenameTiffToMAT()
			newfilename=RenameTiffToMATNew(filename)	//030110
			wave/z matrix3D=$newfilename
			Duplicate/O matrix3D $current3D
			wave/z MATcurrent3D=$current3D
			//Foldername=V9_singleVecField(matrix3D,L_unit,frames)
			//V9_singleVecField(matrix3D,L_unit,frames)
			V9_singleVecField(MATcurrent3D,L_unit,frames)
			wave/z VecLengthWave,GradWave
			V9_recordStats(VecLengthWave,GradWave,j,intensity,direction,V9_dotsizeCorrection(dotsize))
			//saveexperiment
			//setdatafolder root:
			killwaves matrix3D
			//killdatafolder $foldername
			//for (k=0;k<200000;K+=1)
			//endfor
		endfor
		
//		for  (j=0; j<category_velocity; j+=1)
//			V9_kill3DMatrix(intensity,direction,V9_dotsizeCorrection(dotsize),(j*2))
//		endfor
		saveexperiment
//	endfor
	
END

Function V9_kill3DMatrix(intensity,direction,dotsize,velocity)
	variable intensity,direction,dotsize,velocity
	string matrix3Dname
	matrix3Dname=V9_Generate3Dwavename(intensity,direction,dotsize,velocity)
	wave/z matrix3D=$matrix3Dname
	killwaves matrix3D
END


Macro TestRoutine(intensity,direction,pathname)
	variable intensity,direction
	string pathname
	variable i=0
	do 
	 	V9_BatchVectorFieldAnalysis2(intensity,direction,V9_dotsizeCorrection(i),3,40,pathname)
		i=i+1
	while (i<6)
END

Function TestRoutineFunction(intensity,direction,pathname)
	variable intensity,direction
	string pathname
	variable i=0
	do 
//	 	V9_BatchVectorFieldAnalysis2(intensity,direction,V9_dotsizeCorrection(i),3,40,pathname)
	 	V9_BatchVectorFieldAnalysis3(intensity,direction,i,3,40,pathname)
		i=i+1
	while (i<6)
END


		

Function crashtest(intensity,direction,L_unit,frames,pathname)
	variable	intensity,direction,L_unit,frames
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=50
	variable category_dotsize=6
	variable i,j,k
	for (i=0; i<category_dotsize; i+=1)
		for (j=0; j<category_velocity; j+=1)
			filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(i),(j*2))
			V9_LoadSpecifiedStack(pathname,filename)
			newfilename=RenameTiffToMAT()
			wave/z matrix3D=$newfilename
			killwaves matrix3D
		endfor
		saveexperiment
	endfor
	
END

	
///************UNUSED

//Function HistAnalCoreSimple(L_isPosition,L_isFiltered)
//	Variable L_isPosition,L_isFiltered
//	Variable NewGraph=0	
////	NVAR	rnum,cnum,rnum_VXY,cnum_VXY,unit,averaging,averageshift,LayerStart,LayerEnd,gSpeed_threshold,Dest_X,Dest_Y
////	SVAR	wavename_pref
////	String RadWavename,GradWavename,VecLengthWavename,RadWavenameHIST,GradWavenameHIST,VecLengthWavenameHIST
////	String RadWavename_av,GradWavename_av,VecLengthWavename_av,RadWavename_avHIST,GradWavename_avHIST,VecLengthWavename_avHIST
////	String windowname_mag,windowname_deg,windowname_rad,presentWindows
//
//	NVAR rnum_VXY,cnum_VXY,unit,LayerStart,LayerEnd,Dest_X,Dest_Y
//	SVAR wavename_pref
//	String RadWavename,GradWavename,VecLengthWavename,RadWavenameHIST,GradWavenameHIST,VecLengthWavenameHIST
//	String presentWindows
//	SVAR 	AbsoluteOrRelative
//
//	Wave/z VX,VY//,VXav,VYav
//	
//	CheckGraphParametersF()			//020416
//	if (!DataFolderExists("Analysis"))
//		V9_initializeAnalysisFolder()
//	endif
//	NVAR hist2DMask_ON=:analysis:hist2DMask_ON
//	if (L_isFiltered)
//		hist2DMask_ON=1
//	else
//		hist2DMask_ON=0
//	endif
//	
////	rnum=DimSize(VXav, 0)
////	cnum=DimSize(VXav, 1)
//	rnum_VXY=DimSize(VX, 0)
//	cnum_VXY=DimSize(VX, 1)
//	if (L_isPosition==0)
//		AbsoluteOrRelative="\Z08Absolute"
//	else
//		AbsoluteOrRelative="\Z08Relative("+num2str(Dest_X)+","+num2str(Dest_Y)+")"
//	endif
//
//	
////*	RadWavename=wavename_pref+"U"+num2str(Unit)+"_rad"
//	RadWavename=StatnameProc("rad")
//	GradWavename=StatnameProc("deg")
//	VecLengthWavename=StatnameProc("mag")
//
//	RadWavenameHIST=StatHISTnameProc("rad")
//	GradWavenameHIST=StatHISTnameProc("deg")
//	VecLengthWavenameHIST=StatHISTnameProc("mag")
//	
//
//	if (exists(VecLengthWavename)==0)
//		make/n=(rnum_VXY,cnum_VXY) $RadWavename
//		make/n=(rnum_VXY,cnum_VXY) $GradWavename
//		make/n=(rnum_VXY,cnum_VXY) $VecLengthWavename
//
//		make /n=2 $RadWavenameHIST//,$RadWavename_avHIST
//		make /n=2 $GradWavenameHIST//,$GradWavename_avHIST	
//		make /n=2 $VecLengthWavenameHIST//,$VecLengthWavename_avHIST
//
//		NewGraph=1
//	endif
//	
//	
//	Wave/Z RadWave=$RadWavename
//	Wave/Z GradWave=$GradWavename
//	Wave/Z VecLengthWave=$VecLengthWavename
//	Wave/Z RadWaveHIST=$RadWavenameHIST
//	Wave/Z GradWaveHIST=$GradWavenameHIST
//	Wave/Z VecLengthWaveHIST=$VecLengthWavenameHIST
//	Wave/Z VXav,VYav
//
//
////------------------------------------------- down to here was consumed merely for naming the waves
//
//	if (L_isFiltered==0) 
//		if (L_isPosition==1) //relative angle of vectors against a point
//				CalculateAngleRelative(VecLengthWave,VX,VY,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)//,gSpeed_threshold)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//		else			//angle against the screen
//				CalculateAngleAbsolute(VecLengthWave,VX,VY,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//		endif		
//	else
//		if (L_isPosition==1) //relative angle of vectors against a point
//				CalculateAngleRelative(VecLengthWave,VX_filtered,VY_filtered,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)//,gSpeed_threshold)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//		else			//angle against the screen
//				CalculateAngleAbsolute(VecLengthWave,VX_filtered,VY_filtered,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//		endif		
//	endif
//	
//	presentWindows=WinList((wavename_pref+"*"), ";", "" )
//
//	if ((waveexists(GradWave)) && (WhichListItem(HistWinName(2), presentWindows)==(-1)))
//		GradHistShow(GradWave,GradWaveHIST)
////		AppendAveragedVector(GradWaveAV,2)
//		AppendNoiseRemovedHist(GradWaveHIST)		
//	endif
//
//	if ((waveexists(VecLengthWave)) && (WhichListItem(HistWinName(0), presentWindows)==(-1)))
//		SpeedHistShow(VecLengthWave,VecLengthWaveHIST)
////		AppendAveragedVector(VecLengthWaveAV,0)
//		AppendNoiseRemovedHist(VecLengthWaveHIST)		
//	endif
//
//	NVAR G_AllStatFinished		// added on 020129 .. for a permission in ROI routine.
//	G_AllStatFinished=1
//END
