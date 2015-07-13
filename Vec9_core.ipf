#pragma rtGlobals=1		// Use modern global access method.

//031203 
// changed the main routine for the vector calculation; bleaching effect was considered.
// for this reason, LSM calculation was seperated and written as an independent function. see vec9_core2.ipf.


//*************************************************************************************
Function VectorFieldDerive()
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
	//following commented out on 041129	
//	NVAR button_bleachcorrect
//	switch(button_bleachcorrect)		//changed to switch from if-then 040122
//		case 0:		
//			Vec_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber)       		//031203
//			break
//		case 1:		
//			Vec_LSM_bleach(rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate) //031203
//			break
//		case 2:
//			Vec_LSM_bleachV2(rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate) //040122
//			break
//		case 3:
//			Vec_STLO_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber) //041126 test
//			break			
//		default:							
//			Vec_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber)       		//031203
//	endswitch
////	if (button_bleachcorrect==0)
////		Vec_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber)       		//031203
////	else
////		Vec_LSM_bleach(rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate) //031203
////	endif
	Vec_ErrorElimination()
END

//********************
Function Vec_ErrorElimination()
	
	wave/z VX,VY
	Duplicate VX tempVX,VX_error,tempVX_speed,tempnull
	Duplicate VY tempVY,VY_error
	
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


//*************************************************************************************

// Global variables defined here
// averageshift,rnum_VXY,cnum_VXY
//sjould be in the local folder

Function averagingCore(L_VX,L_VY)
	Wave/z L_VX,L_VY
	NVAR	averaging,unit
//	Variable/G rnum_im,cnum_im
	Variable/G	averageshift		//use this parameter when realigning
	Variable/G rnum_VXY=DimSize(VX, 0)
	Variable/G cnum_VXY=DimSize(VX, 1)

	Variable loop_row,loop_col//,rownumber,columnnumber,ave_rownumber,ave_columnnumber
	String VXav_name=(NameOfWave(L_VX)+"av")
	String VYav_name=(NameOfWave(L_VY)+"av")

	//	if (averaging>16)		//averaging as the global variable
	//		averaging=16
	//	endif

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
	
	Variable/G rnum=DimSize(L_VXav, 0)
	Variable/G cnum=DimSize(L_VXav, 1)

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

	SetScale/P x averageshift,averaging,"", L_VXav
	SetScale/P y averageshift,averaging,"", L_VXav
	SetScale/P x averageshift,averaging,"", L_VYav
	SetScale/P y averageshift,averaging,"", L_VYav
	
END

//*********************************************************************************



//************drawing vectors

Function Realign_2Dto1D(L_VXav,L_VYav,L_gridXpoints,L_gridYpoints,L_Xpoints,L_Ypoints)
	Wave	L_VXav,L_VYav,L_gridXpoints,L_gridYpoints,L_Xpoints,L_Ypoints
	NVAR	averaging,averageshift,scale
	Variable L_rnum=DimSize(L_VXav, 0)
	Variable L_cnum=DimSize(L_VXav, 1)
	
	Make/o/N=(L_rnum*L_cnum)/O tem1Dx, tem1Dy
	
	tem1Dx[]=L_VXav[(p-(trunc(p/L_rnum)*L_rnum))][trunc(p/L_rnum)]
	tem1Dy[]=L_VYav[(p-(trunc(p/L_rnum)*L_rnum))][trunc(p/L_rnum)]
	L_gridXpoints[]=Nan
	L_gridYpoints[]=Nan
	L_gridXpoints[]=(p-trunc(p/L_rnum)*L_rnum)*averaging+averageshift
	L_gridYpoints[]=trunc(p/L_rnum)*averaging+averageshift

	L_Xpoints[]=(((p-trunc(p/3)*3) == 0) ? L_gridXpoints[trunc(p/3)] : (((p-trunc(p/3)*3) == 1) ? (tem1Dx[trunc(p/3)]*scale + L_gridXpoints[trunc(p/3)]): NaN))
	L_Ypoints[]=(((p-trunc(p/3)*3) == 0) ? L_gridYpoints[trunc(p/3)] : (((p-trunc(p/3)*3) == 1) ? (tem1Dy[trunc(p/3)]*scale + L_gridYpoints[trunc(p/3)]): NaN))
	
	//KillWaves tem1Dx,tem1Dy
	
END

//************************************************************************************
Function DrawVectorALLcore(L_VXav,L_VYav)
	Wave/z L_VXav,L_VYav
	NVAR unit,LayerStart,LayerEnd,averaging,scale,rnum,cnum
	SVAR wavename_pref

	String Vx_name,Vy_name,VXav_name,VYav_name,Xpoints_name,Ypoints_name,gridXpoints_name, gridYpoints_name,Imagewavename,firstwavename
	String/G WindowName
//get basic parameters	
	rnum=DimSize(L_VXav, 0)
	cnum=DimSize(L_VYav, 1)
	Make/O/N=(3*rnum*cnum)/O Xpoints, Ypoints
	Make/O/N=(rnum*cnum)/O gridXpoints, gridYpoints
//new lines

	Realign_2Dto1D(L_VXav,L_VYav,gridXpoints,gridYpoints,Xpoints,Ypoints)
	
//-----------displaying first layer image-------------------------------

	Imagewavename="root:"+"Mat"+wavename_pref
	//firstwavename=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)
	firstwavename=V9_FirstFrameName()		//030521
//	windowname=wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit)+"Avge"+num2str(Averaging)+"Sc"+num2str(Scale)
	Wave originalMatrix=$Imagewavename
	
	Variable/G rnum_im=DimSize($Imagewavename, 0)
	Variable/G cnum_im=DimSize($Imagewavename, 1)

	Make/O/N=(rnum_im,cnum_im) $firstwavename
	Wave firstwave=$firstwavename
	
	firstwave[][]=originalMatrix[p][q][LayerStart]

	Display;AppendImage $firstwavename
	ModifyImage $firstwavename ctab= {*,*,Grays,0}

//**appending vectors***----------------------------------------------

	AppendToGraph Ypoints vs Xpoints; AppendToGraph  gridYpoints vs gridXpoints
	ModifyGraph tick=2,mirror=1
	//ModifyGraph height={Aspect,1}
	Label left "Y"
	Label bottom "X"
	ModifyGraph lsize=1,mode(gridYpoints)=2
	ModifyGraph rgb(Ypoints)=(65280,0,26112)
	ModifyGraph rgb(gridYpoints)=(0,0,52224)

	ModifyGraph height={Aspect,1}
	SetAxis left 0,cnum_im
	SetAxis bottom 0,rnum_im
	ModifyGraph height={Plan,1,left,bottom}

	TextBox/C/N=text0/A=LB ("\\Z08"+wavename_pref+" "+num2str(LayerStart)+"_"+num2str(LayerEND)+"\runit="+num2str(unit)+" ave="+num2str(Averaging)+"\rscale="+num2str(scale))
	DoWindow/C $VectorFieldWindowName()
END

//**********************************************************************
Function DrawNewScale_core()
	NVAR unit,LayerStart,LayerEnd,averaging,scale
	SVAR wavename_pref
	DoWindow/F $VectorFieldWindowName()
	Realign_2Dto1D(VXav,VYav,gridXpoints,gridYpoints,Xpoints,Ypoints)	//function in above
	if (WhichListItem("Ypoints_filtered", TraceNameList("", ";", 1 ))!=(-1))	//added for filtered vectors 020206
		Realign_2Dto1D(VX_filteredav,VY_filteredav,gridXpoints,gridYpoints,Xpoints_filtered,Ypoints_filtered)
	endif	
	
	TextBox/W=$VectorFieldWindowName()/C/N=text0/A=LB ("\\Z07"+wavename_pref+" "+num2str(LayerStart)+"_"+num2str(LayerEND)+"\runit="+num2str(unit)+" ave="+num2str(Averaging)+"\rscale="+num2str(scale))
End

//*************************************************************************

Function DrawNewAverage_core()
	NVAR unit,LayerStart,LayerEnd,averaging,scale,rnum,cnum
	SVAR wavename_pref
	averagingCore(VX,VY)
	Redimension/N=(rnum*cnum) gridXpoints,gridYpoints
	Redimension/N=(3*rnum*cnum) Xpoints,Ypoints
	DoWindow/F $VectorFieldWindowName()
	Realign_2Dto1D(VXav,VYav,gridXpoints,gridYpoints,Xpoints,Ypoints)
//	if (WhichListItem("Ypoints_filtered", TraceNameList("", ";", 1 ))!=(-1))	//added for filtered vectors 020206
//		Realign_2Dto1D(L_VX_filteredav,L_VY_filteredav,gridXpoints,gridYpoints,Xpoints_filtered,Ypoints_filtered)
//	endif	
	TextBox/W=$VectorFieldWindowName()/C/N=text0/A=LB ("\\Z07"+wavename_pref+" "+num2str(LayerStart)+"_"+num2str(LayerEND)+"\runit="+num2str(unit)+" ave="+num2str(Averaging)+"\rscale="+num2str(scale))

	Calculate_AVstats()				// in VEC9_anal
	if (WhichListItem("Ypoints_filtered", TraceNameList("", ";", 1 ))!=(-1))
		//VecRangeByAVE()			// in VEC9_anal2; modifiy the ranged vector
		wave/z VX_filtered,VY_filtered
		averagingCore(VX_filtered,VY_filtered)
		wave/z VX_filteredav,VY_filteredav
		AddFilteredVec(VX_filteredav,VY_filteredav)
	endif
End

//*************************************************************************


// retired on 031203. 

//Function VectorFieldDerive()
//	SVAR	wavename_pref
//	NVAR	unit,LayerStart,LayerEnd
//	Variable	filenum,n,truncation,WorkingLayerNumber
//	Variable	rownumber,columnnumber,layernumber
//	String	w,filename,currentwavename,VXname,VYname
//	String	firstwavename,wavenamea
//	
//	//PRINTF num2str(unit)
//	//following calculation are done at the root directory
//	wavenamea="Mat"+wavename_pref
//	Wave originalMatrix=$wavenamea
//
//	rownumber=DimSize(originalMatrix, 0)
//	columnnumber=DimSize(originalMatrix, 1)
//	layernumber=DimSize(originalMatrix, 2)
//
//	if (LayerEnd>(layernumber-1))
//		layerEnd=layernumber-1
//	endif
//	
//	WorkingLayerNumber=LayerEnd-LayerStart+1
//	truncation=unit-1
//	
// 	Make/N=(rownumber-truncation,columnnumber, WorkingLayerNumber) derXsub
//	Make/N=(rownumber,columnnumber-truncation, WorkingLayerNumber) derYsub
//	Make/N=(rownumber,columnnumber, WorkingLayerNumber-truncation) derTsub
//	
//	derXsub[][][]=(originalMatrix[p+truncation][q][r+LayerStart]-originalMatrix[p][q][r+LayerStart])/2
//	derYsub[][][]=(originalMatrix[p][q+truncation][r+LayerStart]-originalMatrix[p][q][r+LayerStart])/2
//	derTsub[][][]=(originalMatrix[p][q][r+LayerStart+truncation]-originalMatrix[p][q][r+LayerStart])/2
//
// 	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derX_subave
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derY_subave
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) derT_subave
//	
//	if (unit==3)
//		derX_subave[][][]=(derXsub[p][q][r]+derXsub[p][q+1][r]+derXsub[p][q+2][r]+derXsub[p][q][r+1]+derXsub[p][q+1][r+1]+derXsub[p][q+2][r+1]+derXsub[p][q][r+2]+derXsub[p][q+1][r+2]+derXsub[p][q+2][r+2])/9
//		derY_subave[][][]=(derYsub[p][q][r]+derYsub[p+1][q][r]+derYsub[p+2][q][r]+derYsub[p][q][r+1]+derYsub[p+1][q][r+1]+derYsub[p+2][q][r+1]+derYsub[p][q][r+2]+derYsub[p+1][q][r+2]+derYsub[p+2][q][r+2])/9
//		derT_subave[][][]=(derTsub[p][q][r]+derTsub[p+1][q][r]+derTsub[p+2][q][r]+derTsub[p][q+1][r]+derTsub[p+1][q+1][r]+derTsub[p+2][q+1][r]+derTsub[p][q+2][r]+derTsub[p+1][q+2][r]+derTsub[p+2][q+2][r])/9
//	else
//		derX_subave[][][]=(derXsub[p][q][r]+derXsub[p][q+1][r]+derXsub[p][q][r+1]+derXsub[p][q+1][r+1])/4
//		derY_subave[][][]=(derYsub[p][q][r]+derYsub[p+1][q][r]+derYsub[p][q][r+1]+derYsub[p+1][q][r+1])/4
//		derT_subave[][][]=(derTsub[p][q][r]+derTsub[p+1][q][r]+derTsub[p][q+1][r]+derTsub[p+1][q+1][r])/4
//	endif
//
//	Killwaves derXsub,derYsub,derTsub
//
//// Finished partial derivation
//	
//
//	Make/N=(rownumber-truncation,columnnumber-truncation) VX,VY
//
//	VX=0
//	VY=0
//	
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) XX,XT,YT,XY,YY
//	Make/N=(rownumber-truncation,columnnumber-truncation) XXsum,XTsum,YTsum,XYsum,YYsum
//	
//	XX=	derX_subave*derX_subave	
//	XT=	derX_subave*derT_subave
//	YT=	derY_subave*derT_subave
//	XY=	derX_subave*derY_subave
//	YY=	derY_subave*derY_subave
//	
//	Killwaves derX_subave,derY_subave,derT_subave
//	
//	n=0
//	do
//		if (n>=(WorkingLayerNumber-truncation))
//			break
//		endif
//		XXsum[][]+=XX[p][q][n]
//		XTsum[][]+=XT[p][q][n]
//		YTsum[][]+=YT[p][q][n]
//		XYsum[][]+=XY[p][q][n]
//		YYsum[][]+=YY[p][q][n]
//		n=n+1				
//	while (n<(WorkingLayerNumber-truncation))
//        KillWaves XX,XT,YT,XY,YY
//        
//	VX= -1*(YYsum*XTsum-XYsum*YTsum) / (XXsum*YYsum-XYsum^2)
//	VY= -1*(XXsum*YTsum-XYsum*XTsum) / (XXsum*YYsum-XYsum^2)
//	
//       KillWaves XXsum,XTsum,YTsum,XYsum,YYsum
//       
//	Vec_ErrorElimination()
//END