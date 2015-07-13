#pragma rtGlobals=1		// Use modern global access method.

function SettingDataFolder(w)
	wave w
	setdatafolder GetWavesDataFolder(w,1)
END

Function SetToTopImageDataFolder()
	String igName= WMTopImageGraph() //imagecommon
	if( strlen(igName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif
	DoWindow/F $igName
	Wave w= $WMGetImageWave(igName)	//imagecommon full path to the image: fetches the name of the top graph containing an image
	String waveDF=GetWavesDataFolder(w,1 )	
	SetDataFolder waveDF
	return 1	
END

//************************************************

//***** interactive naming version			020322
// process = mag, deg or rad

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
//***
Function/S StatAvnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process+"av"
	return wave_name
END

Function/S StatAvHISTnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process+"avH"
	return wave_name
END
///****
Function/S StatAvFnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process+"avF"
	return wave_name
END

Function/S StatAvFHISTnameProc(process)
	String process
	String wave_name
	wave_name=V_Prefix()+process+"avFH"
	return wave_name
END

//*****************************************************************
Function/S RoiMagHistName()
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_mag"
	return wave_name
END

Function/S RoiDegHistName()
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_deg"
	return wave_name
END

Function/S RoiMagAVHistName()
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_magAV"
	return wave_name
END

Function/S RoiDegAVHistName()
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_degAV"
	return wave_name
END

//********** interactive version                            020322
// process = mag, deg or rad

Function/S RoiStatHistName(process)
	String process
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_"+process
	return wave_name
END

Function/S RoiAVStatHistName(process)
	String process
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name="ROI_"+wavename_pref+"U"+num2str(Unit)+"_"+process+"AV"
	return wave_name
END

//**** Noise removing Related

Function/S HistNoiseLessName(histname)
	String histname
	String wave_name
	wave_name=histname+"c"
	return wave_name
END

Function/S MagHistNoiseLessName()
	//String histname
	String wave_name
	wave_name=StatHISTnameProc("mag")+"c"
	return wave_name
END

Function/S RoiMagHistNoiseLessName()		//void?
	String wave_name
	SVAR wavename_pref
	NVAR Unit
	wave_name=RoiStatHistName("mag")+"c"
	return wave_name
END

Function/S DegHistNoiseLessName()
	//String histname
	String wave_name
	wave_name=StatHISTnameProc("deg")+"c"
	return wave_name
END
	
Function/S RoiDegHistNoiseLessName()
	//String histname
	String wave_name
	wave_name=RoiStatHISTname("deg")+"c"
	return wave_name
END



Function/s V9_Original3Dwave()
	SVAR wavename_pref
	return ("root:MAT"+wavename_pref)
END

Function/s V9_FirstFrameName()		//030521
	SVAR wavename_pref
	NVAR LayerStart,LayerEnd
	String FrameName=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)
	return FrameName
END

Function/s V9_MidSliceName(src3Dwave)		//030516
	wave src3Dwave
	String MidsliceName=Nameofwave(src3Dwave)+"_mid"
	return MidsliceName
END

Function/s V9_FlowImageName(src3Dwave)		//030516
	wave src3Dwave
	String FIName=Nameofwave(src3Dwave)+"_flo"
	return FIName
END

Function/s V9_ZPimageName(src3Dwave)		//030516
	wave src3Dwave
	String ZPName=Nameofwave(src3Dwave)+"_zPro"
	return ZPName
END



Function/s V9_Tri_directionHistogramWave()

END


Function/S V9_ListAllFolderNames()		//030523
	String objName
	String nameList=""
	Variable index = 0
	do
		objName = GetIndexedObjName("root:", 4, index)
		if (strlen(objName) == 0)
			break
		endif
		//Print objName
		NameList+=objName+";"
		index += 1
	while(1)
	//NameList=(NameList[0,(strlen(NameList)-2)])
	//print NameList
	return NameList 
End


//*********************FOLDER creation

Function V9_initializeAnalysisFolder()		// modified 020905
	String curDF=GetDataFolder(1)
	if (DataFolderExists("Analysis")==0)
		NewDataFolder/S Analysis
	else
		SETDATAFOLDER Analysis
	endif
	

	if (waveexists(W_ROIcoord2D)==0)
		Variable/G Projection_method=1		//average=0; max=1; min=2
		Make/N=(2,2) W_ROIcoord2D
		Make/N=2 W_ROIsize2D
	endif

	NVAR/z G_all_n
	if (NVAR_exists(G_all_n)==0)
		Variable/G G_all_n
		Variable/G G_allSpeedAve
		Variable/G G_allSpeedSdev
		Variable/G G_allAngleX_bar
		Variable/G G_allAngleDeltaDeg
		Variable/G G_allAngleDispersion
		Variable/G G_allAngleRvalue
		

		Variable/G G_AV_n
		Variable/G G_AVSpeedAve
		Variable/G G_AVSpeedSdev
		Variable/G G_AVAngleX_bar
		Variable/G G_AVAngleDeltaDeg
		Variable/G G_AVAngleDispersion
		Variable/G G_AVAngleRvalue
	endif
	NVAR/z G_allSpeedSigma
	if (NVAR_exists(G_allSpeedSigma)==0)
		Variable/G G_allSpeedSigma
	endif
	
	NVAR/z G_AwayRatio
	if (NVAR_exists(G_AwayRatio)==0)
		Variable/G G_AwayRatio
		Variable/G G_AwayForce
		Variable/G G_AwayForceRatio
		Variable/G G_TowardsRatio
		Variable/G G_TowardsForce
		Variable/G G_TowardsForceRatio
		Variable/G G_NormalRatio
		Variable/G G_NormalForce
		Variable/G G_NormalForceRatio
	endif
	
	NVAR/z 	G_AwayFlow
	if (NVAR_exists(G_AwayFlow)==0)
		Variable/G G_AwayFlow
		Variable/G G_AwayFlowRatio
		Variable/G G_TowardsFlow
		Variable/G G_TowardsFlowRatio
		Variable/G G_NormalFlow
		Variable/G G_NormalFlowRatio							
	endif			
	SetDataFolder curDF		

END

Function V9_updateSpeedSigma()		// 030813
	if (DataFolderExists("Analysis")==1)
		String curDF=GetDataFolder(1)
		SetDataFolder Analysis
		NVAR G_all_n
		NVAR G_allSpeedAve		
		NVAR G_allSpeedSigma
		G_allSpeedSigma=G_all_n*G_allSpeedAve		
		SetDataFolder curDF		
	endif
END		
//*************************************
//** should already be in the local folder

//030805 for new HistAnalCore()
Function/s V_returnStatWavenames(isFiltered,isAveraged,param)	// param 0, VX 1, VY, 2, Velwave, 3 Radwave 4, Gradwave, 5, VelwaveH, 6 RadwaveH 7, GradwaveH 
	variable isFiltered,isAveraged,param
	if (isFiltered==0)
		if (isAveraged==0)
			switch(param)	// numeric switch
				case 0:		
					return "VX"
					break
				case 1:		
					return "VY"
					break
				case 2:		
					return StatnameProc("mag")
					break
				case 3:		
					return StatnameProc("rad")
					break
				case 4:		
					return StatnameProc("deg")
					break
				case 5:		
					return StatHISTnameProc("mag")
					break
				case 6:		
					return StatHISTnameProc("rad")
					break
				case 7:		
					return StatHISTnameProc("deg")
					break
				default:		
						
			endswitch
		else
			switch(param)	// numeric switch
				case 0:		
					return "VXav"
					break
				case 1:		
					return "VYav"
					break
				case 2:		
					return StatAvnameProc("mag")
					break
				case 3:		
					return StatAvnameProc("rad")
					break
				case 4:		
					return StatAvnameProc("deg")
					break
				case 5:		
					return StatAvHISTnameProc("mag")
					break
				case 6:		
					return StatAvHISTnameProc("rad")
					break
				case 7:		
					return StatAvHISTnameProc("deg")
					break
				default:		
						
			endswitch		
		
		endif
	else
		if (isAveraged==0)
			switch(param)	// numeric switch
				case 0:		
					return "VX_filtered"
					break
				case 1:		
					return "VY_filtered"
					break
				case 2:		
					return StatnameProc("mag")
					break
				case 3:		
					return StatnameProc("rad")
					break
				case 4:		
					return StatnameProc("deg")
					break
				case 5:		
					return StatHISTnameProc("mag")
					break
				case 6:		
					return StatHISTnameProc("rad")
					break
				case 6:		
					return StatHISTnameProc("deg")
					break
				default:		
						
			endswitch
		else
			switch(param)	// numeric switch
				case 0:		
					return "VX_filteredav"
					break
				case 1:		
					return "VY_filteredav"
					break
				case 2:		
					return StatAvnameProc("mag")
					break
				case 3:		
					return StatAvnameProc("rad")
					break
				case 4:		
					return StatAvnameProc("deg")
					break
				case 5:		
					return StatAvHISTnameProc("mag")
					break
				case 6:		
					return StatAvHISTnameProc("rad")
					break
				case 7:		
					return StatAvHISTnameProc("deg")
					break
				default:		
						
			endswitch		
		
		endif		
	
	
	endif
END


Function PrintFilterParameters()	// 040111
	SettingDataFolder(WaveRefIndexed("",0,1)) 
	variable sf
	if (DataFolderExists(":GraphParameters")==0)
		InitGraphParameters()
	endif
		String AbsoluteOrRelative=V_CoordinateInfo()
		NVAR/z  G_checkVel=:GraphParameters:G_checkVel
		NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
		NVAR/z G_checkAngleNOT=:GraphParameters:G_checkAngleNOT
		NVAR/z G_checkInt=:GraphParameters:G_checkInt
		NVAR G_checkImgMask=:GraphParameters:G_checkImgMask
		NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
		NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove
		SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName
		NVAR/z G_ContinuumRange=:GraphParameters:G_ContinuumRange
	
		wave/z wV=:GraphParameters:W_VelRange
		wave/z wA=:GraphParameters:W_AngleRange
		wave/z wI=:GraphParameters:W_IntRange
		wave/z wR=:GraphParameters:W_ROIcoord	
		String V_txt,A_txt,A0_txt,I_txt,Mask_txt,ROI_txt,SPR_txt
		if (G_checkVel==1)
			V_txt=num2str(wV[0])+" - "+num2str(wV[1])
		else
			V_txt="all"
		endif
		if (G_checkAngle==1)
			if (wA[1]>0)
				A_txt=num2str(wA[0])+" - +"+num2str(wA[1])
			else
				A_txt=num2str(wA[0])+" - "+num2str(wA[1])
			endif
			if (G_checkAngleNOT==1)
				A0_txt="   Angle exclude: "
			else
				A0_txt="   Angle: "
			endif			
		else
			A0_txt="   Angle: "		
			A_txt="all"
		endif
		if  (G_checkInt==1)
			I_txt=num2str(wI[0])+" - "+num2str(wI[1])
		else	
			I_txt="all"
		endif
		if (G_checkImgMask==1) 
			Mask_txt="Image Mask: "+S_ImgMaskName
		else
			Mask_txt="No Image Mask Applied"
		endif
		
		if (G_checkRoi==1)
			ROI_txt="  ROI:"+num2str(wR[0][0])+","+num2str(wR[1][0])+","+num2str(wR[0][1])+","+num2str(wR[1][1])+"\r"
		else
			ROI_txt="  no ROI"+"\r"
		endif
		
		if (G_checkSinglePixRemove==1)
			SPR_txt=" 1 Pix Signal Remove- range:±"+num2str(G_ContinuumRange)
		else
			SPR_txt=" no Single Pix Remove"
		endif
		string printout =AbsoluteOrRelative+"\rVelocity: "+V_txt+A0_txt+A_txt+"\rIntensity: "+I_txt+"   "+Mask_txt+ROI_txt+SPR_txt 
		print printout
END	


//*************UNUSED naming (old)

//**** Following procedures defines the used names.
//Function/S RadWavenameProc()
//	String wave_name
//	SVAR wavename_pref
//	NVAR Unit
//	wave_name=wavename_pref+"U"+num2str(Unit)+"_rad"
//	return wave_name
//END

//Function/S GradWavenamePoc()
//	String wave_name
//	SVAR wavename_pref
//	NVAR Unit
//	wave_name=wavename_pref+"U"+num2str(Unit)+"_deg"
//	return wave_name
//END

//Function/S VecLengthWavenameProc()
//	String wave_name
//	SVAR wavename_pref
//	NVAR Unit
//	wave_name=wavename_pref+"U"+num2str(Unit)+"_mag"
//	return wave_name
//END


// commentalized 030729
////********************
//Function ParameterInitialize()
//
//	NVAR/z Dest_X
//	if (NVAR_Exists(Dest_X))
//		Variable/G Dest_X
//		Dest_X=0
//	endif
//
//	NVAR/z Dest_Y
//
//	if (NVAR_Exists(Dest_Y))
//		Variable/G Dest_Y
//		Dest_Y=0
//	endif
//	
//	NVAR/z isPosition
//	if (NVAR_Exists(isPosition))
//		Variable/G isPosition
//		isPosition=0
//	endif
//END

//************************************