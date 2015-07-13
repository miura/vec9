#pragma rtGlobals=1		// Use modern global access method.

//020908 for measureing rotating slugs
//
// List of the fnctions within this ipf file
//	 MultiVectorField(matrix3D,L_unit,frames,L_averaging,L_scale,L_destX,L_desty)
//	 BringtheStatsForwardForSave(imagepath)
//	 Vec9_MeasureROImulti(matrix3D,L_unit,frames,left,right,bottom,top)
//	 V9_MultimeasureFilteredInt(matrix3D,L_unit,frames,minInt,maxInt)
//	 V2_normalize2Thistogram(w)	

//	multiaccumulator(pref,type) collects histogram data in a folder to three waves, each for towards, normal and away. 
//	then K_histstatsspecial(pref) do the stats to average, get SEM and so on to graph it. 
//	MultipleVectorField_Filtered()		

//First prepare the vector field by MultiVectorField(matrix3D,L_unit,frames,L_averaging,L_scale,L_destX,L_desty)
// and then do V9_MultimeasureFilteredInt(MATs408aH,3,20,80,254)
// to visualize the tracks.

Function MultiVectorField(matrix3D,L_unit,frames,L_averaging,L_scale,L_destX,L_desty)
	wave matrix3D
	variable L_unit,frames,L_averaging,L_scale,L_destX,L_desty 

	string L_wavename_pref=nameofwave(matrix3D)
	variable iteration=trunc(DimSize(matrix3D,2)/frames)
	printf "iterations %d\r",iteration
	variable lastnumber=iteration*frames
	printf "lastrame %d\r",lastnumber

	if (L_scale<1)
		L_scale=1
	endif
//	L_averaging =L_averaging*2+1	//correction for the popup menue

//-------------GetNames---------	
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])
	if (L_unit==1)
		L_unit=3
	elseif (L_unit==2)
		L_unit=2
	endif
	variable L_LayerStart
	variable L_LayerEnd
	String	FolderName,L_windowname,WindowMatching
	String/G path			//string at the root directory
	string imagename
	variable i
	for (i=0;i<lastnumber;i+=frames)
		setdatafolder root:	
		L_LayerStart=i
		L_LayerEnd=L_LayerStart+frames-1
		printf "now process frame %d to %d",L_LayerStart,L_LayerEnd
		L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
		printf "Window Name: %s\r", L_windowname
		FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
		path=("root:"+Foldername)
		printf "Folder Name: %s\r", FolderName
//		WindowMatching=Winlist(L_windowname,";","")
//		//print windowmatching
//		if (WhichListItem(L_windowname, WindowMatching)!=(-1))
//			DoWindow/F  $L_windowname
//			Print "Same Parameter as the previously shown plot"
//		else
////-------------------------------------------
		if (DataFolderExists(path))
			print "Vectors are already present. Use the existing waves"
		else
			NewDataFolder $path
			String/G wavename_pref=L_wavename_pref
			Variable/G Unit=L_unit
			Variable/G Layerstart=L_Layerstart
			Variable/G LayerEnd=L_LayerEnd
			VectorFieldDerive()
			path=("root:"+Foldername+":")
			MoveWave VX $path
			MoveWave VY $path
			MoveWave VX_error $path
			MoveWave VY_error $path
			MoveString wavename_pref $path
			MoveVariable Unit $path
			MoveVariable LayerStart $path
			MoveVariable LayerEnd $path
		endif

//*********local data folder
		path=("root:"+Foldername)
		setdatafolder $path
		Variable/G averaging=L_averaging
		averagingCore(VX,VY)
		Variable/G scale=L_scale
		DrawVectorALLcore(VXav,VYav)

		NVAR/z isPosition
		if (NVAR_exists(isPosition)==0)
			HistStatParameterInit()
		endif		// 020129
		NVAR Dest_x				//020908
		dest_x=L_destx			//020908
		NVAR Dest_y				//020908
		dest_y=L_desty			//020908
		NVAR isPosition
		isPosition=1
		
		HistAnalCore()//1,1,0) //parameter=1, isPosition=0, isFilterd=0 (not filtered)
		path=("root:"+Foldername)
//	endif
//********analysis	

	DoWindow/F $L_windowname
	imagename=L_wavename_pref+num2str(L_LayerStart)+"_"+num2str(L_LayerEnd)
	//ModifyImage $imagename ctab= {*,*,Grays,1}
	SavePICT/O/P=images/T="TIFF"/B=144
	BringtheStatsForwardForSave("images")
		
	setdatafolder root:
	endfor
	
END

Function BringtheStatsForwardForSave(imagepath)
	string imagepath
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
 	if (WhichListItem(HistWinName(0), presentWindows)!=(-1))	
		DoWindow/F $HistWinName(0)	//mag
		//wave/z Vwave=$StatnameProc("mag")
		//TextBox_Hist_AllVecInfo(Vwave,HistWinName(0))
		//DoUpdate		
		SavePICT/O/P=$imagepath/T="TIFF"/B=72
	else
		print "No Speed Stat Window. should do the stat again!"	
	endif
 	if (WhichListItem(HistWinName(2), presentWindows)!=(-1))	
		DoWindow/F $HistWinName(2)	//deg
		//wave/z Gwave=$StatnameProc("deg")
		//TextBox_Hist_AllVecInfo(Gwave,HistWinName(2))
		//DoUpdate		
		SavePICT/O/P=$imagepath/T="TIFF"/B=72
	else
		print "No Angle Stat Window. should do the stat again!"	
	endif
	SetDataFolder curDF	
	
END

function Vec9_MeasureROImulti(matrix3D,L_unit,frames,left,right,bottom,top)
	wave matrix3D
	variable L_unit,frames,left,right,bottom,top
	string L_wavename_pref=nameofwave(matrix3D)
	variable iteration=trunc(DimSize(matrix3D,2)/frames)
	variable lastnumber=iteration*frames
	printf "lastrame %d\r",lastnumber	
	variable L_LayerStart
	variable L_LayerEnd
	
	variable speed_bins=40
	variable angle_bins=40
	
	string speed2Dname=L_wavename_pref+"F"+num2str(frames)+"_vel"
	Make/O/N=(speed_bins,iteration) $speed2Dname
	wave/z speed2D=$speed2Dname
	string speedavgname=L_wavename_pref+"F"+num2str(frames)+"_velavg"
	string speedsdname=L_wavename_pref+"F"+num2str(frames)+"_velsd"
	Make/O/N=(iteration) $speedavgname,$speedsdname
	wave/z speedavg=$speedavgname
	wave/z speedsd=$speedsdname

	variable velocity_binwidth=5/speed_bins

	string angle2Dname=L_wavename_pref+"F"+num2str(frames)+"_ang"
	Make/O/N=(angle_bins,iteration) $angle2Dname
	string angleavgname=L_wavename_pref+"F"+num2str(frames)+"_angavg"
	string anglesdname=L_wavename_pref+"F"+num2str(frames)+"_angsd"
	Make/O/N=(iteration) $angleavgname,$anglesdname

	wave/z angle2D=$angle2Dname
	wave/z angleavg=$angleavgname
	wave/z anglesd=$anglesdname

	variable angle_binwidth=360/angle_bins

	String	FolderName,L_windowname,WindowMatching
	String/G path			//string at the root directory
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])

	String MagWaveName//=StatnameProc("mag")
	String DegWaveName//=StatnameProc("deg")
	String ROI_magHname,ROI_degHname//,ROI_magAVHname,ROI_degAVHname
	Variable lowpass=0


	variable i
	variable j=0
	for (i=0;i<(lastnumber);i+=frames)
		setdatafolder root:
		L_LayerStart=i
		L_LayerEnd=L_LayerStart+frames-1
		printf "now process frame %d to %d\r",L_LayerStart,L_LayerEnd					
//		L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
		FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)	
		path=("root:"+Foldername)
		printf "Folder Name: %s\r", FolderName
		if (DataFolderExists(path))
			setDataFolder $path
//			NVAR Unit,Layerstart,LayerEnd
			NVAR unit,rnum_VXY,cnum_VXY
			SVAR wavename_pref

			MagWaveName=StatnameProc("mag")
			DegWaveName=StatnameProc("deg")
		//String MagAVWaveName=StatAvnameProc("mag")
		//String DegAVWaveName=StatAvnameProc("deg")
			wave w_mag=$MagWaveName
			wave w_deg=$DegWaveName
		//wave w_magAV=$MagAVWaveName
		//wave w_degAV=$DegAVWaveName
// 030729 commented out
//			SVAR/z AbsoluteOrRelative
//			NVAR/z Dest_X,Dest_Y
			NVAR/z isPosition			
//			if (isPosition==0)
//				AbsoluteOrRelative="\Z08Absolute"
//			else
//				AbsoluteOrRelative="\Z08Relative("+num2str(Dest_X)+","+num2str(Dest_Y)+")"
//			endif

	//		String ROI_magHname,ROI_degHname//,ROI_magAVHname,ROI_degAVHname
			ROI_magHname=RoiStatHistName("mag")
			ROI_degHname=RoiStatHistName("deg")
			//ROI_magAVHname=RoiAVStatHistName("mag")
			//ROI_degAVHname=RoiAVStatHistName("deg")

			Make/o/n=2 $ROI_magHname,$ROI_degHname//,$ROI_magAVHname,$ROI_degAVHname
			Wave ROI_magH=$ROI_magHname
			Wave ROI_degH=$ROI_degHname
//			Wave ROI_magAVH=$ROI_magAvHname
//			Wave ROI_degAVH=$ROI_degAVHname
			
			//--non averaged
			Duplicate/o/R=[left,right][bottom,top] w_mag w_mag_lowpass
			//print nameofwave(w_mag)
			wavestats/Q w_mag_lowpass
			printf "HIghest speed Vector: %f\r", V_max
			lowpass=0
			if (V_max>10)
				print "deleted super largevalues (>10) "
				w_mag_lowpass[][]=((w_mag_lowpass[p][q]>10) ? Nan : w_mag_lowpass[p][q])
				Lowpass=1
				Duplicate/o  w_mag_lowpass W_mag1D		///R=[V_left,V_right][V_bottom,V_top]
			else
				Duplicate/o/R=[left,right][bottom,top]  w_mag W_mag1D
			endif
			Killwaves w_mag_lowpass
			
			Duplicate/o/R=[left,right][bottom,top] w_deg W_deg1D
		
			wavestats/q W_mag1D
			speedavg[j]=V_avg
			speedsd[j]=V_sdev
	
					
//			Variable binnumber=(trunc(V_max/binwidth)+4)
//			if ((binnumber<20) || (numtype(binnumber)!=0))
//		 		binnumber=20
//		 	endif

			Histogram/B={0,velocity_binwidth,speed_bins} W_mag1D,ROI_magH
			speed2D[][j]=ROI_magH[p]
			
//			NormalizeHistogram(W_mag1D,ROI_magH)
//			VelocityNoiseRemovalNorm(W_mag1D,ROI_magH)		//new 020321
			
			wavestats/q W_deg1D
			
			angleavg[j]=V_avg
			anglesd[j]=V_sdev
			
			if (isPosition==0)
				Histogram/B={0,angle_binwidth,angle_bins} W_deg1D,ROI_degH
			else
				Histogram/B={-180,angle_binwidth,angle_bins} W_deg1D,ROI_degH
			endif
			
			angle2D[][j]=ROI_degH[p]

		endif
		setdatafolder root:
		j+=1
	endfor
									
END


Function V9_MultimeasureFilteredInt(matrix3D,L_unit,frames,minInt,maxInt)
	wave matrix3D
	variable L_unit,frames,minInt,maxInt
	string L_wavename_pref=nameofwave(matrix3D)
	variable iteration=trunc(DimSize(matrix3D,2)/frames)
	variable lastnumber=iteration*frames
	printf "lastrame %d\r",lastnumber	
	variable L_LayerStart
	variable L_LayerEnd
	setdatafolder root:	
	Variable val_min1=0//ROIcoord[1][0]
	Variable val_max1=5//ROIcoord[1][1]
	Variable val_min2=minInt//ROIcoord[0][0]
	Variable val_max2=maxInt//ROIcoord[0][1]
	
	variable speed_bins=40
	variable angle_bins=40
	string suffix="int"+num2str(minInt)+"_"+num2str(maxInt)+"F"+num2str(frames)
	string speed2Dname=L_wavename_pref+suffix+"_vel"
	Make/O/N=(speed_bins,iteration) $speed2Dname
	wave/z speed2D=$speed2Dname
	string speedavgname=L_wavename_pref+suffix+"_velavg"
	string speedsdname=L_wavename_pref+suffix+"_velsd"
	Make/O/N=(iteration) $speedavgname,$speedsdname
	wave/z speedavg=$speedavgname
	wave/z speedsd=$speedsdname

	variable velocity_binwidth=5/speed_bins

	string angle2Dname=L_wavename_pref+suffix+"_ang"
	Make/O/N=(angle_bins,iteration) $angle2Dname
	string angleavgname=L_wavename_pref+suffix+"_angavg"
	string anglesdname=L_wavename_pref+suffix+"_angsd"
	Make/O/N=(iteration) $angleavgname,$anglesdname

	wave/z angle2D=$angle2Dname
	wave/z angleavg=$angleavgname
	wave/z anglesd=$anglesdname

	variable angle_binwidth=360/angle_bins
	String	FolderName,L_windowname,WindowMatching
	String/G path			//string at the root directory
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])

	string matrix3Dname
	String firstframename
		
	variable i
	variable j=0
	for (i=0;i<(lastnumber);i+=frames)
		setdatafolder root:
		L_LayerStart=i
		L_LayerEnd=L_LayerStart+frames-1
		printf "now process frame %d to %d\r",L_LayerStart,L_LayerEnd					
		L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
		FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)	
		path=("root:"+Foldername)
		printf "Folder Name: %s\r", FolderName
		if (DataFolderExists(path))
			setDataFolder $path
			printf "setdatafolder to: %s", path
			NVAR isPoisition	//030805 
			HistAnalCore()//1,1,0) 030805			
			wave/z VecLengthWave=$StatnameProc("mag")
			SVAR wavename_pref
			NVAR LayerStart,LayerEnd
			matrix3Dname="root:MAT"+wavename_pref
			wave/z matrix3D=$matrix3Dname
			firstframename=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)+"mx"
			if (!waveexists($firstframename))
				Make/O/N=(DimSize(matrix3D, 0),DimSize(matrix3D, 1)) $firstframename
				//Variable slices=LayerEnd-Layerstart+1
				Wave/z firstframe=$firstframename	
				V9_ZprojectionFirstFrame(matrix3D,firstframe,LayerStart,LayerEnd)
			else
				Wave/z firstframe=$firstframename	
			endif
			NVAR Unit
			Duplicate/O/R=[trunc(unit/2),(Dimsize(firstframe,0)-trunc(unit/2)-1)][trunc(unit/2),(Dimsize(firstframe,1)-trunc(unit/2)-1)] firstframe tempfirstframe
			//wave/z DegWave=$StatnameProc("deg")
			if (!V9_checkSameDim2D(VecLengthWave,tempfirstframe))
				abort "wave dimension error: V9_hist2Danal_IntA() tempfirstframe and Degwave"
			endif
	
//	wave/z ROIcoord=:analysis:W_ROIcoord2D
//	Variable val_min1=ROIcoord[1][0]
//	Variable val_max1=ROIcoord[1][1]
//	Variable val_min2=ROIcoord[0][0]
//	Variable val_max2=ROIcoord[0][1]
			Duplicate/O tempfirstframe maskVelInt
			//print "made maslVellint"
			V9_GenerateMask2para(VecLengthWave,tempfirstframe,maskVelInt,val_min1,val_max1,val_min2,val_max2)	

			wave/z ROIcoord=:analysis:W_ROIcoord2D	
			ROIcoord[1][0]=val_min1
			ROIcoord[1][1]=val_max1
			ROIcoord[0][0]=val_min2
			ROIcoord[0][1]=val_max2
			
			Vec_V2DFilter_v2(maskVelInt)

			wave/z VX_filtered,VY_filtered
			averagingCore(VX_filtered,VY_filtered)
			wave/z VX_filteredav,VY_filteredav
			AddFilteredVec(VX_filteredav,VY_filteredav)
			NVAR L_isPosition=isPosition
//			NVAR hist2DMask_ON=:analysis:hist2DMask_ON
//			hist2DMask_ON=L_isPosition
			//NVAR V_windowtype=:Analysis:V_windowtype
			//V_windowtype=4			// means this is a VI graph: accessed for text info
			//HistAnalCore(1,L_isPosition,1)
			V_VelAngleCalc(1)
			V_showHists()
			wave/z Velwave=$StatnameProc("mag")
			wave/z Gradwave=$StatnameProc("deg")
	
			wavestats/q Velwave
			speedavg[j]=V_avg
			speedsd[j]=V_sdev

			make/o/N=(speed_bins) tempHist
			Histogram/B={0,velocity_binwidth,speed_bins} Velwave,tempHist
			speed2D[][j]=tempHist[p]

			wavestats/q Gradwave
			angleavg[j]=V_avg
			anglesd[j]=V_sdev
			if (L_isPosition==0)
				Histogram/B={0,angle_binwidth,angle_bins} Gradwave,tempHist
			else
				Histogram/B={-180,angle_binwidth,angle_bins} Gradwave,tempHist
			endif
			
			angle2D[][j]=tempHist[p]
			killwaves tempHist			
						
			DoWindow/F $L_windowname
			SavePICT/O/P=imagesfiltered/T="TIFF"/B=144
			BringtheStatsForwardForSave("imagesfiltered")
			
			j+=1
		endif	
	endfor			
	setdatafolder root:

	SetScale/P x 0,velocity_binwidth,"", $speed2Dname
	SetScale/P x -180,angle_binwidth,"", $angle2Dname
	SetScale/P y 0,10,"", $speed2Dname,$angle2Dname	
	SetScale/P x 0,10,"", $speedavgname,$angleavgname	

	V2_normalize2Thistogram(speed2D)
	V2_normalize2Thistogram(angle2D)	
	Display /W=(360.75,75.5,598.5,404)
	AppendImage angle2D
	ModifyImage $angle2Dname ctab= {*,*,BlueRedGreen,0}
	ModifyGraph margin(left)=65
	ModifyGraph mirror=2
	ModifyGraph lblMargin(left)=24
	ModifyGraph lblLatPos(left)=-113
	Label left "Time"
	Label bottom "Angle"
	ColorScale/N=text0/F=0/H=2/B=1/A=LB/X=-41.09/Y=-1.89
	ColorScale/C/N=text0 image=$angle2Dname, side=2, width=10, fsize=8

	Display /W=(114.75,68.75,353.25,395.75)
	AppendImage speed2D
	ModifyImage $speed2Dname ctab= {*,*,BlueRedGreen,0}
	ModifyGraph margin(left)=65
	ModifyGraph mirror=2
	ModifyGraph lblMargin(left)=24
	ModifyGraph lblLatPos(left)=-113
	Label left "Time"
	Label bottom "Speed"
	ColorScale/N=text0/F=0/H=2/B=1/A=LB/X=-41.09/Y=-1.89
	ColorScale/C/N=text0 image=$speed2Dname, side=2, width=10, fsize=8

	Display /W=(84.75,235.25,479.25,443.75) speedavg
	AppendToGraph/R angleavg
	ModifyGraph mode=4
	ModifyGraph marker=8
	ModifyGraph rgb($angleavgname)=(0,0,65280)
	ModifyGraph opaque=1
	ModifyGraph tick=2
	ModifyGraph lblMargin(left)=5,lblMargin(right)=11
	ModifyGraph lblLatPos(left)=-2
	Label left ("\\s("+speedavgname+") Speed [pix/frame]")
	Label bottom "time [min]"
	Label right ("Angle \\s("+angleavgname+")")
	SetAxis/N=1 left 0,5
	SetAxis right -180,180
	ErrorBars $speedavgname Y,wave=($speedsdname,$speedsdname)
	ErrorBars $angleavgname Y,wave=($anglesdname,$anglesdname)
	TextBox/N=text0/F=0/H=2/B=1/A=LB/X=42.28/Y=93.72 L_wavename_pref			
END

Function V2_normalize2Thistogram(w)		//020911
	wave w
	variable Xrange=Dimsize(w,0)
	variable Yrange=Dimsize(w,1)
	variable HistTotal
	variable i,j
	for (i=0;i<Yrange;i+=1)
		HistTotal=0
		for (j=0;j<Xrange;j+=1)
			HistTotal+=w[j][i]
		endfor
		w[][i]=w[p][i]/HistTotal
	endfor
END


// 040120

Function DoSimpleDirection()
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i
	string CurrentVecWinName
 	if (ItemsInList(presentWindows)>1)
 		for (i=0;i<ItemsInList(presentWindows);i+=1)
 			setdatafolder root:
 			CurrentVecWinName=StringFromList(i, presentWindows)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				VEC9_TriDirection_Histo()
			endif
		endfor
	endif
	SetDataFolder curDF	
END

//-------------------------

Function MultipleVectorField_Filtered()		//040121 for multiple measurement with relative positions & filtering
	String	L_wavename_pref
	setdatafolder root:
	prompt	L_wavename_pref, "Prefix of the TIFF files?", popup  WaveList("Mat*",";","")
	Variable	L_unit=3
	prompt	L_unit, "What is the side for the gradient detection? (2 or 3)", popup "3;2;"
	Variable	L_LayerStart=0
	prompt	L_LayerStart, "Starting Layer No.?"
	Variable L_averaging
	Prompt L_averaging, "How Many Pixels for Averaging?", popup "3;5;7;9;11;13;15;"
	Variable L_scale=25
	Prompt L_scale, "Scaling of the vector:" 
	Variable L_button_bleachcorrect=0
	Prompt L_button_bleachcorrect, "Bleaching Correction:",popup "off;on_LinearFit;on_RawValues"  
	variable L_OptimizationMethod 	
	Prompt L_OptimizationMethod, "Optimization Method:",popup "TemporalLocal;SpatialTemporalLocal3x3;SpatialTemporalLocal5x5" 	
	Variable FramesPerField
	Prompt FramesPerField, "How many frames / vector field?"
	Variable FieldNumber
	Prompt FieldNumber, "How many fields?"
	Variable L_cx
	Prompt L_cx,"reference x"
	Variable L_cy
	Prompt L_cy,"reference y"
	Variable LV_min
	Prompt LV_min,"Velocity Min"
	Variable LV_max
	Prompt LV_max,"Velocity Max"
	Variable LI_min
	Prompt LI_min,"Intensity Min"
	Variable LI_max
	Prompt LI_max,"Intensity Max"
	Variable BackInt
	Prompt BackInt,"Background Intensity"
	Variable SpeedFactor
	Prompt SpeedFactor,"Speed Factor"
	variable ,L_ContinuumRange
	Prompt L_ContinuumRange,"Single Pixel filtering Range"
	Doprompt "Input Parameters::",L_wavename_pref,L_unit,L_LayerStart,FramesPerField,FieldNumber,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod
	if (V_flag)
		Abort "Processing Canceled"
	endif
	Doprompt "Input Filter Parameters::",L_cx,L_cy,LV_min,LV_max,LI_min,LI_max,BackInt,SpeedFactor,L_ContinuumRange
	if (V_flag)
		Abort "Processing Canceled"
	endif 
	string maskwavename=V9_getMaskedImgName()
	if (L_unit==1)
		L_unit=3
	elseif (L_unit==2)
		L_unit=2
	endif
	L_averaging =L_averaging*2+1	//correction for the popup menue
	L_button_bleachcorrect-=1	
	
	MultiVecField_Filtered_core(L_wavename_pref,L_unit,L_LayerStart,FramesPerField,FieldNumber,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod,L_cx,L_cy,LV_min,LV_max,LI_min,LI_max,BackInt,SpeedFactor,L_ContinuumRange,maskwavename)


end

Function MultiVecField_Filtered_core(L_wavename_pref,L_unit,L_LayerStart,FramesPerField,FieldNumber,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod,L_cx,L_cy,LV_min,LV_max,LI_min,LI_max,BackInt,SpeedFactor,L_ContinuumRange,maskwavename)
	string L_wavename_pref,maskwavename
	variable L_unit,L_LayerStart,FramesPerField,FieldNumber,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod,L_cx,L_cy,LV_min,LV_max,LI_min,LI_max,BackInt,SpeedFactor,L_ContinuumRange
	
	Wave originalMatrix=$L_wavename_pref //matrix name
	Variable L_LayerEnd,layernumber,count
	layernumber=DimSize(originalMatrix, 2)
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])
//*************************	
	if (FramesPerField<3)
		FramesPerField=3
	endif
	if ((FramesPerField*FieldNumber+L_LayerStart)>layernumber)
		FieldNumber=trunc((layernumber-L_LayerStart)/FramesPerField)
	endif
	If (fieldnumber<1)
		fieldnumber=1
	endif
//**********************************	
	count=0
	do
		L_LayerEnd=(L_LayerStart+FramesPerField-1)
		DoalltoshowVectorField_Core(L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod)
		DoWindow/F $(VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit))
		SetToTopImageDataFolder()
		NVAR isPosition,Dest_X,Dest_Y			
		isPosition=1
		Dest_x=L_cx
		Dest_y=L_cy
		if (!DataFolderExists(":GraphParameters"))
			InitGraphParameters()
		endif
//		FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
//		path=("root:"+Foldername)
//		-----------------------------------------
		HistAnalCore()
		V9_switchANGLErange()			//030729
		//DoWindow/F $VectorFieldWindowName()
		//V_Cleardrawings() 		// clear ROI
		//V_printResults()
		//if (V_CheckForceHistPresence()==1)		//030813
		//	V_FlowHist()
		//endif		
		
		//-------------------- Filtering: set parameters
		wave/z Vrange=:GraphParameters:W_VelRange
		Vrange[0]=LV_min
		Vrange[1]=LV_max
		wave/z Irange=:GraphParameters:W_IntRange
		Irange[0]=LI_min
		Irange[1]=LI_max
		SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName
		S_ImgMaskName=maskWaveName

		NVAR G_backgroundIntensity= :GraphParameters:G_backgroundIntensity
		G_backgroundIntensity=BackInt
		NVAR G_speedfactor= :GraphParameters:G_speedfactor
		G_speedfactor=SpeedFactor
		
		NVAR/z G_checkVel=:GraphParameters:G_checkVel
		NVAR/z G_checkInt=:GraphParameters:G_checkInt
		NVAR/z G_checkImgMask=:GraphParameters:G_checkImgMask
		NVAR/z G_checkFilterVecDisplay=:GraphParameters:G_checkFilterVecDisplay
		NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove			
		NVAR/z G_ContinuumRange=:GraphParameters:G_ContinuumRange		
		
		G_checkVel=1
		G_checkInt=1
		G_checkFilterVecDisplay=1
		if (L_ContinuumRange!=0)
			G_checkSinglePixRemove=1
			G_ContinuumRange=L_ContinuumRange
		endif
		
		if (cmpstr(S_ImgMaskName,"NoApporopriateImage")==0)
			G_checkImgMask=0
		else
			G_checkImgMask=1
		endif

		SetToTopImageDataFolder()
		V9_refreshCheckFiltering()	
		V9_DoFilterValues()
		V_updateRangeDrawing()
//		NVAR G_checkPrintHist=:GraphParameters:G_checkPrintHist
//		if (G_checkPrintHist)
//			V_printResults()
//		endif
		V_CheckRoughDir() //030813
//		if (V_CheckForceHistPresence()==1)		//030813
			V_FlowHist()
//		endif
		setdatafolder root:	
		L_Layerstart=(L_Layerstart+FramesPerField)
		count=count+1
	while (count<fieldnumber)
	
END


Function/S V9_getMaskedImgName()			//020901 //V2 030726 from current folder //040121
	SetDataFolder "root:"
	String maskList=WaveList("MSK*",";","")
	String	maskWaveName
	if (cmpstr(masklist,"")!=0)
		prompt	maskWaveName, "which image?", popup maskList  
		DoPrompt "Select a bianry tiff Image for masking", maskWaveName
		maskWaveName="root:"+maskWaveName
	else
		maskWaveName="NoApporopriateImage"
	endif
	return maskWaveName
END



Function Multiple_Filtering()		//040121 for multiple filtering
	Variable LV_min
	Prompt LV_min,"Velocity Min"
	Variable LV_max
	Prompt LV_max,"Velocity Max"
	Variable LI_min
	Prompt LI_min,"Intensity Min"
	Variable LI_max
	Prompt LI_max,"Intensity Max"
	Doprompt "Input Filter Parameters::"LV_min,LV_max,LI_min,LI_max
	if (V_flag)
		Abort "Processing Canceled"
	endif 
	Multiple_FilteringCore(LV_min,LV_max,LI_min,LI_max)
end

Function Multiple_FilteringCore(LV_min,LV_max,LI_min,LI_max)
	variable LV_min,LV_max,LI_min,LI_max		
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i
	string CurrentVecWinName
 	if (ItemsInList(presentWindows)>1)
 		for (i=0;i<ItemsInList(presentWindows);i+=1)
 			setdatafolder root:
 			CurrentVecWinName=StringFromList(i, presentWindows)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				SetToTopImageDataFolder()
				wave/z Vrange=:GraphParameters:W_VelRange
				Vrange[0]=LV_min
				Vrange[1]=LV_max
				wave/z Irange=:GraphParameters:W_IntRange
				Irange[0]=LI_min
				Irange[1]=LI_max
				
				NVAR/z G_checkVel=:GraphParameters:G_checkVel
				NVAR/z G_checkInt=:GraphParameters:G_checkInt
				NVAR/z G_checkFilterVecDisplay=:GraphParameters:G_checkFilterVecDisplay
				G_checkVel=1
				G_checkInt=1
				G_checkFilterVecDisplay=1
		
				SetToTopImageDataFolder()
				V9_refreshCheckFiltering()	
				V9_DoFilterValues()
				V_updateRangeDrawing()

				V_CheckRoughDir() //030813
				V_FlowHist()
				setdatafolder root:	
			endif
		endfor
	endif
	//k_custom060410(LV_min,LV_max,LI_min,LI_max)//temporalily 060410	
	SetDataFolder curDF		
END

Function Multiple_Filtering_vel()		//040121 for multiple filtering
	Variable LV_min
	Prompt LV_min,"Velocity Min"
	Variable LV_max
	Prompt LV_max,"Velocity Max"
	Doprompt "Input Filter Parameters::"LV_min,LV_max
	if (V_flag)
		Abort "Processing Canceled"
	endif 
	
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i
	string CurrentVecWinName
 	if (ItemsInList(presentWindows)>1)
 		for (i=0;i<ItemsInList(presentWindows);i+=1)
 			setdatafolder root:
 			CurrentVecWinName=StringFromList(i, presentWindows)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				SetToTopImageDataFolder()
				wave/z Vrange=:GraphParameters:W_VelRange
				Vrange[0]=LV_min
				Vrange[1]=LV_max
//				wave/z Irange=:GraphParameters:W_IntRange
//				Irange[0]=LI_min
//				Irange[1]=LI_max
				
				NVAR/z G_checkVel=:GraphParameters:G_checkVel
//				NVAR/z G_checkInt=:GraphParameters:G_checkInt
				NVAR/z G_checkFilterVecDisplay=:GraphParameters:G_checkFilterVecDisplay
				G_checkVel=1
//				G_checkInt=1
				G_checkFilterVecDisplay=1
		
				SetToTopImageDataFolder()
				V9_refreshCheckFiltering()	
				V9_DoFilterValues()
				V_updateRangeDrawing()

				V_CheckRoughDir() //030813
				V_FlowHist()
				setdatafolder root:	
			endif
		endfor
	endif
	SetDataFolder curDF		
END


// multiaccumulator(pref,type) collects histogram data in a folder to three waves, each for towards, normal and away. 
// then K_histstatsspecial(pref) do the stats to average, get SEM and so on to graph it. 
// function
function accumulator(srcwave,away,normal,towards,datanum)
	wave srcwave,away,normal,towards
	variable datanum
	away[datanum]=srcwave[0]
	normal[datanum]=srcwave[1]
	towards[datanum]=srcwave[2]
end	

Function multiaccumulator(pref,type)
//	variable startN,endN
	string pref,type
	string awayname=pref+type+"_away"
	string normname=pref+type+"_normal"	
	string towname=pref+type+"_towards"
	//string allwaves=WaveList("*",";","")
	string allwaves=WaveList(("*"+type+"*"),";","")
	variable allwavesnum=ItemsInList(allwaves)
	make/O/N=(allwavesnum) $awayname,$normname,$towname
	wave away=$awayname
	wave normal=$normname
	wave towards=$towname
	string currentname
	variable i
	for (i=0;i<allwavesnum;i+=1)
		 currentname=StringFromList(i, allwaves)
		 wave cw=$currentname
		 print currentname
		 accumulator(cw,away,normal,towards,i)
	endfor
end

function accumulatorBin(srcwave,away,towards,datanum)
	wave srcwave,away,towards
	variable datanum
	away[datanum]=srcwave[0]
	towards[datanum]=srcwave[1]
end	

Function multiaccumulatorBin(pref,type)
//	variable startN,endN
	string pref,type
	string awayname=pref+type+"_away"
	string towname=pref+type+"_towards"
	//string allwaves=WaveList("*",";","")
	string allwaves=WaveList(("*"+type+"*"),";","")
	variable allwavesnum=ItemsInList(allwaves)
	make/O/N=(allwavesnum) $awayname,$towname
	wave away=$awayname
	wave towards=$towname
	string currentname
	variable i
	for (i=0;i<allwavesnum;i+=1)
		 currentname=StringFromList(i, allwaves)
		 wave cw=$currentname
		 print currentname
		 accumulatorBin(cw,away,towards,i)
	endfor
end


Function K_histstats(pref,type)
//	variable startN,endN
	string pref,type
	string awayname=pref+type+"_away"
	string normname=pref+type+"_normal"	
	string towname=pref+type+"_towards"
	wave away=$awayname
	wave normal=$normname
	wave towards=$towname
	string avgname=pref+type+"_avg"
	string sdname=pref+type+"_sd"
	string semname=pref+type+"_sem"
	Make/o/n=3 $avgname,$sdname,$semname
	wave avg=$avgname
	wave sd=$sdname
	wave sem=$semname
	wavestats/q away
	//printf "Away: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 
	avg[0]=V_avg
	sd[0]=V_sdev
	sem[0]=V_sdev/(V_npnts)^0.5
	wavestats/q normal
	//printf "Normal: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5)
	avg[1]=V_avg
	sd[1]=V_sdev
	sem[1]=V_sdev/(V_npnts)^0.5	 	
	wavestats/q towards
	//printf "Towards: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 	
	avg[2]=V_avg
	sd[2]=V_sdev
	sem[2]=V_sdev/(V_npnts)^0.5
end

// 060511
Function K_histstatsBin(pref,type)
//	variable startN,endN
	string pref,type
	string awayname=pref+type+"_away"
	string towname=pref+type+"_towards"
	wave away=$awayname
	wave towards=$towname
	string avgname=pref+type+"_avg"
	string sdname=pref+type+"_sd"
	string semname=pref+type+"_sem"
	Make/o/n=2 $avgname,$sdname,$semname
	wave avg=$avgname
	wave sd=$sdname
	wave sem=$semname
	wavestats/q away
	//printf "Away: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 
	avg[0]=V_avg
	sd[0]=V_sdev
	sem[0]=V_sdev/(V_npnts)^0.5
	
	wavestats/q towards
	//printf "Towards: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 	
	avg[1]=V_avg
	sd[1]=V_sdev
	sem[1]=V_sdev/(V_npnts)^0.5
end

Function K_histstatsspecial(pref) //040620
	string pref
	//setdatafolder root:
	Make/O/N=3/T Direction
	Direction={"Away","Normal","Towards"}	
	K_histstats(pref,"FR")
	K_histstats(pref,"PV")
	//wave Direction
	wave avg1=$(pref+"FR_avg")
	wave avg2=$(pref+"PV_avg")
	wave sem1=$(pref+"FR_sd")
	wave sem2=$(pref+"PV_sd")
	Display avg1 vs Direction
	AppendToGraph/R avg2 vs Direction
	ModifyGraph width=150,height=150
	SetAxis right 0,0.3 
	SetAxis left 0,0.45 
	ModifyGraph offset($nameofwave(avg1))={-0.25,0}
	ModifyGraph offset($nameofwave(avg2))={0.25,0}
	ModifyGraph axisEnab(bottom)={0,1},catGap(bottom)=0.6,barGap(bottom)=0
	
	ErrorBars $nameofwave(avg1) Y,wave=(sem1,sem1)
	ErrorBars $nameofwave(avg2) Y,wave=(sem2,sem2)
	ModifyGraph tick(left)=2,mirror(bottom)=2,tick(right)=2
	ModifyGraph hbFill($nameofwave(avg2))=6,rgb($nameofwave(avg2))=(0,15872,65280)
	Label bottom "Direction"
	string op="Flow Rate\s("+nameofwave(avg1)+") [%]"
	Label left op
	op="Protein Velocity\s("+nameofwave(avg2)+") [pix/frame]"
	Label right op
	op=pref
	TextBox/C/N=text0/A=MC op
	
END

//for Flow Rates original data. do ratio calculation for wach instances.

Function K_histstats060410(pref,type)
//	variable startN,endN
	string pref,type
	string awayname=pref+type+"_away"
	string normname=pref+type+"_normal"	
	string towname=pref+type+"_towards"
	wave away=$awayname
	wave normal=$normname
	wave towards=$towname
	string avgname=pref+type+"_avg"
	string sdname=pref+type+"_sd"
	string semname=pref+type+"_sem"
	Make/o/n=3 $avgname,$sdname,$semname
	wave avg=$avgname
	wave sd=$sdname
	wave sem=$semname
	wavestats/q away
	//printf "Away: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 
	avg[0]=V_avg
	sd[0]=V_sdev
	sem[0]=V_sdev/(V_npnts)^0.5
	wavestats/q normal
	//printf "Normal: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5)
	avg[1]=V_avg
	sd[1]=V_sdev
	sem[1]=V_sdev/(V_npnts)^0.5	 	
	wavestats/q towards
	//printf "Towards: %f sd: %f sem: %f\r",V_avg,V_sdev,(V_sdev/(V_npnts)^0.5) 	
	avg[2]=V_avg
	sd[2]=V_sdev
	sem[2]=V_sdev/(V_npnts)^0.5
end

//060710
function K_addsup1wave(srcwave)
	wave srcwave
	variable i,total
	total=0
	for (i=0;i<numpnts(srcwave);i+=1)
		total+=srcwave[i]
	endfor
	return total
end

function accumulator060410(srcwave1,srcwave2,srcwave3,away1,normal1,towards1,away2,normal2,towards2,away3,normal3,towards3,datanum)
	wave srcwave1,srcwave2,srcwave3,away1,normal1,towards1,away2,normal2,towards2,away3,normal3,towards3
	variable datanum

	if (waveexists(srcwave1)==0)
		print ("missing:"+nameofwave(srcwave1))
		abort "wavemissing1"
	endif
	if (waveexists(srcwave2)==0)
		print ("missing:"+nameofwave(srcwave2))
		abort "wavemissing2"
	endif
	if (waveexists(srcwave3)==0)
		print ("missing:"+nameofwave(srcwave3))
		abort "wavemissing3"
	endif	
	
	make/o/n=3 tempdata1,tempdata2,tempdata3
	tempdata1[]=srcwave1[p]
	tempdata2[]=srcwave2[p]
	tempdata3[]=srcwave3[p]


	variable totalflowFULL=K_addsup1wave(tempdata1)
	tempdata1/=	totalflowFULL
	tempdata2/=totalflowFULL

	variable totalflowHigh=K_addsup1wave(tempdata3)
	tempdata3/=totalflowHigh	
	
	away1[datanum]=tempdata1[0]
	normal1[datanum]=tempdata1[1]
	towards1[datanum]=tempdata1[2]
	
	away2[datanum]=tempdata2[0]
	normal2[datanum]=tempdata2[1]
	towards2[datanum]=tempdata2[2]	

	away3[datanum]=tempdata3[0]
	normal3[datanum]=tempdata3[1]
	towards3[datanum]=tempdata3[2]	

end	

//specified for doing statistics, to calculate the ratio average together with filtered valuses. 
Function multiaccumulator060710()

//	variable startN,endN
	setdatafolder root:
	string pref="ts39"
//	string pref="ts20"

	string type1p, type2p,type3p
	type1p="root:ts32FlowRate_full"
	type2p="root:ts32FlowRate_low"
	type3p="root:ts32FlowRate_high"
//
//	type1p="root:ts20FlowRate_full"
//	type2p="root:ts20FlowRate_low"
//	type3p="root:ts20FlowRate_high"
		
	string type1="full"
	string type2="low"
	string type3="high"

	string suffix="FRH3"

	string type1awayname=pref+type1+"FR_away"
	string type1normname=pref+type1+"FR_normal"	
	string type1towname=pref+type1+"FR_towards"
	//string allwaves=WaveList("*",";","")

	string type2awayname=pref+type2+"FR_away"
	string type2normname=pref+type2+"FR_normal"	
	string type2towname=pref+type2+"FR_towards"

	string type3awayname=pref+type3+"FR_away"
	string type3normname=pref+type3+"FR_normal"	
	string type3towname=pref+type3+"FR_towards"
		
	setdatafolder $type1p	
	string allwaves=WaveList("*H3",";","")
	variable allwavesnum=ItemsInList(allwaves)

		make/O/N=(allwavesnum) $type1awayname,$type1normname,$type1towname
	setdatafolder $type2p	
		make/O/N=(allwavesnum) $type2awayname,$type2normname,$type2towname
	setdatafolder $type3p	
		make/O/N=(allwavesnum) $type3awayname,$type3normname,$type3towname

	setdatafolder root:	

		wave away1=$(type1p+":"+type1awayname)
		wave normal1=$(type1p+":"+type1normname)
		wave towards1=$(type1p+":"+type1towname)

		wave away2=$(type2p+":"+type2awayname)
		wave normal2=$(type2p+":"+type2normname)
		wave towards2=$(type2p+":"+type2towname)
		
		wave away3=$(type3p+":"+type3awayname)
		wave normal3=$(type3p+":"+type3normname)
		wave towards3=$(type3p+":"+type3towname)
		
	string currentname
	variable i
	for (i=0;i<allwavesnum;i+=1)
		 currentname=StringFromList(i, allwaves)
		 wave cw1=$(type1p+":"+currentname)
		 wave cw2=$(type2p+":"+currentname)
		 wave cw3=$(type3p+":"+currentname)

		accumulator060410(cw1,cw2,cw3,away1,normal1,towards1,away2,normal2,towards2,away3,normal3,towards3,i)
		 print currentname
	endfor
end