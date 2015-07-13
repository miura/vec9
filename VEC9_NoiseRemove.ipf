#pragma rtGlobals=1		// Use modern global access method.

#include "VEC9_DataFolderIO"
#include "VEC9_graphs"
#include <Image Common>
//020321 kota Miura
// Functions developed for removing noise contribution to the Velocity histogram of Vector field.
//
//**************************************
Function LoadLib_SigmoidParam()

	LoadData /D/I/L=1 "SigmoidNoise_lib"

END

Function LoadNoiseParameters()	//new 020322
	String curDF=GetDataFolder(1)
	if (DataFolderExists("root:NoiseParameterWaves"))
		SetDataFolder root:NoiseParameterWaves
		print "no new noise folder"
	else
		NewDataFolder/O/S root:NoiseParameterWaves
		print "new data folder made for noise"
	endif
	if (waveexists(Noise15Sig_x)==0)		
		LoadData /D/I/L=1 "SigmoidNoise_lib"
	endif		
	SetDataFolder curDF
End

//**** get the parameters for the sigmoid curve from loaded wave ****//
// problems with the naming
Function IntSigmoidBase(x_value)
	Variable x_value
	String curDF=GetDataFolder(1)
	SetDataFolder root:NoiseParameterWaves	
	Wave/z Noise15Sig_x,Noise15Sig_base
	return interp(x_value,Noise15Sig_x,Noise15Sig_base)
	SetDataFolder curDF
END

Function IntSigmoidMax(x_value)
	Variable x_value
	String curDF=GetDataFolder(1)
	SetDataFolder root:NoiseParameterWaves	

	Wave/z Noise15Sig_x,Noise15Sig_max
	return interp(x_value,Noise15Sig_x,Noise15Sig_max)
	SetDataFolder curDF
END

Function IntSigmoidXhalf(x_value)
	Variable x_value
	String curDF=GetDataFolder(1)
	SetDataFolder root:NoiseParameterWaves	
	Wave/z Noise15Sig_x,Noise15Sig_xhalf
	return interp(x_value,Noise15Sig_x,Noise15Sig_xhalf)
	SetDataFolder curDF
END

Function IntSigmoidRate(x_value)
	Variable x_value
	String curDF=GetDataFolder(1)
	SetDataFolder root:NoiseParameterWaves	
	Wave/z Noise15Sig_x,Noise15Sig_rate
	return interp(x_value,Noise15Sig_x,Noise15Sig_rate)
	SetDataFolder curDF
END

//**********************
Function GenerateNoiseHistogram(framenum,histname,histpnts)
	Variable framenum,histpnts
	String histname

	if (waveexists(root:NoiseParameterWaves:Noise15Sig_x)==0)		//new 020322
		LoadNoiseParameters()
	endif
	//print histname
	
	CheckGraphParametersF()								//020416
	NVAR binwidth=:GraphParameters:G_binwidth		//020416

	Make/o/n=(histpnts) $histname				// changed 020416
	wave/z NoiseHist=$histname
	SetScale/P x 0,binwidth,"", NoiseHist 	
	Variable Sig_base
	Sig_base=IntSigmoidBase(framenum)
	Variable Sig_max
	Sig_max=IntSigmoidMax(framenum)
	Variable Sig_xhalf
	Sig_xhalf=IntSigmoidXhalf(framenum)
	Variable Sig_rate
	Sig_rate=IntSigmoidRate(framenum)
	
	NoiseHist[]=Sig_base + Sig_max/(1+exp(-(x-Sig_xhalf)/Sig_rate))		//Sigmoid curve, from IGOR manual 

END

Function DoGenerateNoiseHistogram()
	Variable framenum=40
	prompt framenum, "Frame Numbers?"
	Variable histpnts=20
	prompt histpnts, "Histgram Pnts?"
	String histname="noise_hist"
	prompt histname, "Name of Noise Histogram?"
	DoPrompt "Set Noise Histogram Parameters",framenum,histname,histpnts
	if (V_flag)
		Abort "Processing Canceled"
	endif
	GenerateNoiseHistogram(framenum,histname,histpnts)
END


//************************ sampling method for removing nosie ***************** 020417

Function SampleNoiseHistogram(framenum,histname,histpnts)	// 020417
	Variable framenum,histpnts
	String histname

	CheckGraphParametersF()								
	NVAR binwidth=:GraphParameters:G_binwidth		

	Make/o/n=(histpnts) $histname	
	wave/z NoiseHist=$histname
	SetScale/P x 0,binwidth,"", NoiseHist 	
	wave/z NoiseROIdimensions
	if (waveexists(NoiseROIdimensions)==0)
		//DoAlert 0,"No ROI setting"
		Abort "No ROI setting"
		//return 0	
	endif

	String MagWaveName=StatnameProc("mag")
	wave w_mag=$MagWaveName
	Variable R_left=NoiseROIdimensions[0]
	Variable R_right=NoiseROIdimensions[1]
	Variable R_bottom=NoiseROIdimensions[2]
	Variable R_top=NoiseROIdimensions[3]

	Duplicate/o/R=[R_left,R_right][R_bottom,R_top] w_mag w_mag_roi
	//Variable ROI_width=V_right-V_left
	//Variable ROI_height=V_top-V_bottom
	//Redimension/N=(ROI_width*ROI_height) w_mag_roi		
	Histogram/B={0,binwidth,histpnts} w_mag_roi,NoiseHist
	wavestats/Q w_mag_roi
	NoiseHist=NoiseHist/V_npnts
			
END

Function Get_Noise_ROI() : GraphMarquee	// 020417
	String igName= WMTopImageGraph() //imagecommon

	if( strlen(igName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif

	DoWindow/F $igName
	Wave w= $WMGetImageWave(igName)	//imagecommon full path to the image: fetches the name of the top graph containing an image
	String saveDF=GetDataFolder(1)
	String waveDF=GetWavesDataFolder(w,1 )
	SetDataFolder waveDF
	Make/O/N=4 NoiseROIdimensions
	NVAR Unit
	GetMarquee left, bottom
	if (V_Flag == 0)
		Print "There is no marquee"
	else
		if (Unit==3)
			V_Left=trunc(V_Left-1)
			V_Right=trunc(V_Right-1)
			V_bottom=trunc(V_bottom-1)
			V_top=trunc(V_top-1)
		endif // otherwise, unit=2 and can be remained same
		NoiseROIdimensions={V_left,V_Right,V_bottom,V_top}
	endif

	SetDataFolder saveDF
END

Function SetNoiseMethod()	// 020417
	SettingDataFolder(WaveRefIndexed("",0,1))
	variable NoiseMethod
	if (DataFolderExists(":GraphParameters"))
		NVAR M_NoiseMethod=:GraphParameters:G_noisemethod
		NoiseMethod=M_NoiseMethod	
	else
		NoiseMethod=0
		InitGraphParameters()
	endif
	prompt NoiseMethod, "Noise Method?", popup "Simulation Fitting;Sampling Noise"
	DoPrompt "Set Noise Method:",NoiseMethod
	if (V_flag)
		Abort "Processing Canceled"
	endif
	NoiseMethod=NoiseMethod-1
	NVAR L_NoiseMethod=:GraphParameters:G_noisemethod
	L_NoiseMethod=NoiseMethod
END

//*******************************
// this function should be in the local folder, not the root

Function VelocityNoiseRemoval(VelWave,VelWaveHist)			// this version is currently unused
	wave VelWave,VelWaveHist
	String VelWaveHistName=NameOfWave(VelWaveHist )
	String NoiseHistName=VelWaveHistName+"Noise"
	Variable VectorNumber=numpnts(VelWave)
	//print "Vector Number"
	//print VectorNumber
	//print "Hist Total Vector"
	//print GetHistTotal(SignalVelocityHist)
	NVAR startframe=LayerStart
	NVAR endframe=LayerEnd
	Variable framenumber=endframe-startframe
	Variable histpnts=numpnts(VelWaveHist)	 	
	//noise removal module should be added here.
	GenerateNoiseHistogram(framenumber,NoiseHistName,histpnts)
	wave/z NoiseHist
	Variable NoiseHistfactor
	NoiseHist[]=NoiseHist[p]*VectorNumber
	NoiseHistfactor=(VelWaveHist[0]/NoiseHist[0])
	//Print "NoiseHistfactor"
	//print NoiseHistfactor
	Duplicate/O VelWaveHist SignalVelocityHist						//created a wave for Noise removal
	SignalVelocityHist[]=VelWaveHist[p]-(NoiseHist[p]*NoiseHistfactor)		// Noise Removed Wave (histogram) = SignalVelocity
//	SignalVelocityHist[] = ((SignalVelocityHist[p] <0) ? 0 : SignalVelocityHist[p])
//	Variable SignalVelocityAV								//moved to texbox dialogue
//	SignalVelocityAV=HistWeightedAverage(SignalVelocity)
	SignalVelocityHist[]=(SignalVelocityHist[p]/GetHistTotal(SignalVelocityHist))		//Normalize

END

//***follwoing is for the readily normalized vector

Function VelocityNoiseRemovalNorm(VelWave,VelWaveHist)
	wave VelWave,VelWaveHist
	String VelWaveHistName=NameOfWave(VelWaveHist )
	String NoiseHistName=VelWaveHistName+"Noise"
	String SignalVelocityHistName=HistNoiseLessName(VelWaveHistName)

	String curDF=GetDataFolder(1)
		
	NVAR startframe=LayerStart
	NVAR endframe=LayerEnd
	Variable framenumber=endframe-startframe
	Variable histpnts=numpnts(VelWaveHist)			 	

	if (!(DataFolderExists(":GraphParameters")))
		InitGraphParameters()
	endif
	
	//** following is the new lines ******** 020417
	NVAR NoiseMethod=:GraphParameters:G_noisemethod
	wave/z NoiseROIdimensions
	if (waveexists(NoiseROIdimensions)==0)
		NoiseMethod=0
	endif
	if (NoiseMethod==0)
		//if (waveexists($NoiseHistName) ==0)
			GenerateNoiseHistogram(framenumber,NoiseHistName,histpnts)
		//endif
		//print "Noise: simulation fitting..."
	else
		if (NoiseMethod==1)
			 SampleNoiseHistogram(framenumber,NoiseHistName,histpnts)
			 print "sampling noise..."
		endif
	endif

//	Variable PointNumbers=(Dimsize(VelWave,0) * Dimsize(VelWave,1))
	WaveStats/Q VelWave
	Variable PointNumbers=V_npnts
	
	SetDataFolder curDF	
	wave/z NoiseHist=$NoiseHistName
	Variable NoiseHistfactor
	NoiseHistfactor=(VelWaveHist[0]/NoiseHist[0])
	Duplicate/O VelWaveHist $SignalVelocityHistName						//created a wave for Noise removal
	Wave SignalVelocityHist=$SignalVelocityHistName
	
	SignalVelocityHist[]=VelWaveHist[p]-(NoiseHist[p]*NoiseHistfactor)		// Noise Removed Wave (histogram) = SignalVelocity
//	SignalVelocityHist[] = ((SignalVelocityHist[p] <0) ? 0 : SignalVelocityHist[p])
//	Variable NSVU=(1/allpnts(WinMode))	// 020326 NormalizedSingleVectorUnit // 020417 deleted
//	Variable NSVU=(1/GetHistTotal(VelWaveHist))	 // 020417
	Variable NSVU=(1/PointNumbers)
	SignalVelocityHist[] = ((SignalVelocityHist[p] <NSVU) ? 0 : SignalVelocityHist[p])  //020326 if the value at a bin is less than that of single vector, it is 0.

END

///////////////////////////////////////grad wave stat

Function GradNoiseRemoval(DegWaveHist,VelWaveHist,WinMode)			//simply subtract the noise offset since the NOISE vector is in 360 degrees
	wave DegWaveHist,VelWaveHist
	Variable WinMode
	String NoiseHistName=(NameofWave(VelWaveHist)+"Noise")
	wave/z NoiseHist=$NoiseHistName
	Variable NoiseHistfactor
	NoiseHistfactor=(VelWaveHist[0]/NoiseHist[0])
		
//	String DegWaveName=NameOfWave(DegWave)
	String DegWaveHistName=NameOfWave(DegWaveHist)
	Duplicate/o DegWaveHist $HistNoiseLessName(DegWaveHistName) //$DegHistNoiseLessName()
	//print DegHistNoiseLessName()
	wave NoiseLess=$HistNoiseLessName(DegWaveHistName)	//$DegHistNoiseLessName()
	//NoiseLess[]=0
	wave VelNoise=$HistNoiseLessName(NameOfWave(VelWaveHist))
	//print NameOfWave(VelNoise)
	Variable NoiseOffset=(GetHistTotal(NoiseHist)/18)*NoiseHistfactor
	//Printf "Noise hist factor: %5.5f\r", NoiseHistfactor
	//Printf "Noise offset in Deg graph: %f\r", NoiseOffset
	//print NoiseOffset
	NoiseLess[]=(NoiseLess[p]-NoiseOffset)
	Variable NSVU=(1/allpnts(WinMode))	 // 020417
	NoiseLess[] = ((NoiseLess[p] <NSVU) ? 0 : NoiseLess[p])	


END

Function GradNoiseRemovalROI()			//simply subtract the noise offset since the NOISE vector is in 360 degrees


END

////////////////////////////////Statistics

Function GetHistTotal(histwave)
	wave histwave
	Variable hist_sum=0
	Variable i
	for(i=0;i<numpnts(histwave);i+=1)	
		hist_sum+=histwave[i]
	endfor
	//printf "Total Point Number of %s is %f\r", (NameofWave(histwave)), hist_sum
	return hist_sum
END

//*****************************

Function HistWeightedAverage(histwave) //histwavename = wave containing noise removed Velocity Histogram: 
	wave histwave
	Variable weighted_sum=0
	Variable i
	CheckGraphParametersF()								//020416
	NVAR binwidth=:GraphParameters:G_binwidth		//020416
	for(i=0;i<numpnts(histwave);i+=1)	
		//Weighted_sum+=(histwave[i]*pnt2x(histwave,i))					//deleted on 020409
//		Weighted_sum+=(histwave[i]*(0.125+pnt2x(histwave,i)))			//inserted 020409 
		Weighted_sum+=(histwave[i]*((binwidth/2)+pnt2x(histwave,i)))			//modified 020416

	endfor
	return (Weighted_sum/GetHistTotal(histwave))
End

//********************************
Function VelNoiseRemovedAV(WinMode)
	Variable WinMode
	String OriginalMagHist
	if (WinMode==6)
		OriginalMagHist=StatHISTnameProc("mag")				
	else	
		OriginalMagHist=RoiStatHistName("mag")				
	endif
	wave/z NoiselessWave=$HistNoiseLessName(OriginalMagHist)
	return HistWeightedAverage(NoiselessWave)	
END

//**********************************

Function nonNoisePntsN(WinMode)		//020326
	Variable WinMode
	String OriginalMagHist
	if (WinMode==6)
		OriginalMagHist=StatHISTnameProc("mag")
	else
		OriginalMagHist=RoiStatHistName("mag") //  something like "ROI_Statname("mag")" is required
	endif			
	wave/z NoiselessWave=$HistNoiseLessName(OriginalMagHist)
	return GetHistTotal(NoiselessWave)
END

Function nonNoisePnts(WinMode)		//020326 returns the number of points after removing noise
	Variable WinMode
 	return (trunc(nonNoisePntsN(WinMode)*allpnts(WinMode)))
END

Function allpnts(WinMode)		//020326 returns the number of points in original MAG 2D wave (number of all vectors)
	variable WinMode
	String OriginalMag
	if (WinMode==6)
		OriginalMag=StatnameProc("mag")
	else
		OriginalMag="W_mag1D" //  something like "ROI_Statname("mag")" is required
	endif
	wave/z OM=$OriginalMag
	Wavestats/Q OM
	return V_npnts
END

/////////////////////////////////////// Graphing

//*******************
Function AppendNoiseRemovedHist(OrigHistWave)
	Wave OrigHistWave
	String NoiselessHistName=HistNoiseLessName(NameOfWave(OrigHistWave))
	//printf "name of the appending wave is %s\r",NoiselessHistName
//	print NoiselessHistName
	Wave NoiseLessWave=$NoiselessHistName
	AppendToGraph/R NoiseLessWave				
	ModifyGraph rgb($NoiselessHistName)=(52224,52224,0)
	ModifyGraph useNegPat($NoiselessHistName)=1
	ModifyGraph mode=5
	ModifyGraph hbFill($NoiselessHistName)=4	
	String LabelRight="Vectors (\\s("+NoiselessHistName+")denoise Filtered)"
	Label right LabelRight
	SetAxis/A/N=2 right
	BringTheFrontTraceBottom()					//new 020327
END

Function AppendNoiseRemoedHistGrad()
	
END

//******************** doesn't need this???
//Function AppendNoiseRemovedHistROI(OrigHistWave)	//w_av = deg or mag
//	Wave OrigHistWave
//	String SignalVelocityHistName=RoiMagHistNoiseLessName()
//	Wave Velwave=$SignalVelocityHistName
//	String name_w
//	AppendToGraph/R VelWave
//	ModifyGraph rgb($name_w)=(52224,52224,0)
//	ModifyGraph mode=5
	//TextBox_Hist_AveragedInfo(w_av,HistWinName(param))
//END

//******

//**********************************

Function TextBox_Hist_NoiseLessInfo(WinMode)
	//wave NoiseLessWave
	Variable WinMode
	TextBox/W=$HistWinName(WinMode)/C/N=AllVecInfo/A=RT "Denoise Avg="+num2str(VelNoiseRemovedAV(WinMode))+"\rcPnts="+num2str(nonNoisePnts(WinMode))  //new 020321
END

Function NoiseLessSpeedHistShow(WinMode)		//020325
	Variable WinMode
	String NoiselessHistName
	if (WinMode==6)
		NoiselessHistName=MagHistNoiseLessName()
	else
		NoiselessHistName=RoiMagHistNoiseLessName()
	endif
	Wave NoiseLessWave=$NoiselessHistName

	Display /W=(500,50,750,300) ,NoiseLessWave
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
//	ModifyGraph rgb($NoiselessHistName)=(52224,52224,0)
	String LabelLeft="Vectors (\\s("+NoiselessHistName+")denoise Filtered)"
	Label left LabelLeft
	Label bottom "Speed [arb]"
	SetAxis/A/N=1 left
	
	DoWindow/C $HistWinName(WinMode)
	TextBox_Hist_NoiseLessInfo(WinMode)
End

//********
Function DisplayNoiseLessSpeed(mode)
	String Mode
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	String histwavename
	Variable WinMode
	if (stringmatch(mode,"ALL")==1)
		histwavename=MagHistNoiseLessName()
		WinMode=6
	else
		histwavename=RoiMagHistNoiseLessName()	
		WinMode=7
	endif
		
	Wave/z histwave=$histwavename
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )	
	if (WaveExists(histwave)==1)
		if (WhichListItem(HistWinName(WinMode), presentWindows)==(-1))
			NoiseLessSpeedHistShow(WinMode)
		else
			DoWindow/F	$HistWinName(WinMode)
		endif
	else
		print "No Such Wave in this folder"
	endif
	SetDataFolder curDF	
END

