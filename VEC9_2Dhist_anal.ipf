#pragma rtGlobals=1		// Use modern global access method.


// for dual masking 020830		Kota Miura
//020830 finished main filtering part: ROI on the way: linking with the main waves not done




Function V9_setTProjectionMethod()		//new 020905
	variable projectionMethod=2
	prompt projectionMethod,"Which method for the z(time)-projection?", popup "Average;Max;Min"
	DoPrompt "Z-Projection Method", projectionMethod
	String CurrentDataFolder=VEC9_Set_CurrentPlotDataFolder()	
	if (DataFolderExists("Analysis")==0)
		V9_initializeAnalysisFolder()
	endif
	NVAR  pm=:analysis:Projection_method
	pm=projectionMethod-1
	setdatafolder root:
end
Function V9_getTProjectionMethod()		//new 020905
	variable projectionMethod=2
	String CurrentDataFolder=VEC9_Set_CurrentPlotDataFolder()	
	if (DataFolderExists("Analysis")==0)
		V9_initializeAnalysisFolder()
	endif
	NVAR  pm=:analysis:Projection_method
	return pm
end
//****************************
Function V9_GenerateMask(src2DWave,destMask2Dwave,val_min,val_max)
	wave src2DWave,destMask2Dwave
	Variable val_min,val_max
	if (V9_checkSameDim2D(src2DWave,destMask2Dwave)==0)
		Abort "error in V9_GenerateMask(src2DWave,destMask2Dwave,val_min,val_max): not same dimension"
	endif	
	destMask2Dwave=0
	destMask2Dwave[][]=( ((val_min<src2Dwave[p][q] ) && (src2Dwave[p][q] < val_max)) ? 1 : 0)
END

Function V9_GenerateMask2para(src2DWave1,src2DWave2,destMask2Dwave,val_min1,val_max1,val_min2,val_max2)
	wave src2DWave1,src2DWave2,destMask2Dwave
	Variable val_min1,val_max1,val_min2,val_max2
	if (V9_checkSameDim2D(src2DWave1,destMask2Dwave)==0)
		Abort "error in V9_GenerateMask(src2DWave1,destMask2Dwave,val_min,val_max): not same dimension"
	endif	
	if (V9_checkSameDim2D(src2DWave2,destMask2Dwave)==0)
		Abort "error in V9_GenerateMask(src2DWave2,destMask2Dwave,val_min,val_max): not same dimension"
	endif	
	destMask2Dwave=0
	printf "generated mask wave: %s drom %s min %d max %d \r",nameofwave(destMask2Dwave), nameofwave(src2DWave1),val_min1, val_max1
	printf "generated mask wave: %s from %s min %d max %d \r",nameofwave(destMask2Dwave), nameofwave(src2DWave2),val_min2, val_max2
	destMask2Dwave[][]=( ((val_min1<=src2Dwave1[p][q] ) && (src2Dwave1[p][q] <= val_max1) && (val_min2<=src2Dwave2[p][q]) && (src2Dwave2[p][q] <= val_max2)) ? 1 : 0)
END


//************* utility: chech functions

Function V9_checkSameDim2D(src2Dwave1,src2Dwave2)		//fin
	wave src2Dwave1,src2Dwave2
	variable same=0
	if ( (Dimsize(src2Dwave1,0)==Dimsize(src2Dwave2,0)) && (Dimsize(src2Dwave1,1)==Dimsize(src2Dwave2,1)))
		same=1
	endif
	return same
end

//*** combination of masks 
Function/S V9_combine2DMasks(maskwave1,maskwave2)		//fin
	wave maskwave1,maskwave2
	if (V9_checkSameDim2D(maskwave1,maskwave2)==0)		
		Abort "error in V9_combine2DMasks(maskwave1,maskwave2): not same dimension"
	endif
	String Mask_combinedName=NameofWave(maskwave2)+NameofWave(maskwave2)
	Make/N=(Dimsize(maskwave1,0),Dimsize(maskwave1,1)) $Mask_combinedName
	wave mask_con=$Mask_combinedName
	mask_con[][]=( ( (maskwave1[p][q]==1) && (maskwave2[p][q]==1) )? 1 : 0)
	return Mask_combinedName
END

Function/S V9_combine2DMasksImg(maskwave_gen,maskwave_img)		//image version
	wave maskwave_gen,maskwave_img
	if (V9_checkSameDim2D(maskwave_gen,maskwave_img)==0)
		if ( Dimsize(maskwave_gen,0)<Dimsize(maskwave_img,0) )
			NVAR Unit
			Duplicate/R=[0,(Dimsize(maskwave_img,0)-unit+1)][0,(Dimsize(maskwave_img,1)-unit+1)] maskwave_img temp_img
		else
			Abort "error in V9_combine2DMasksImg(maskwave_gen,maskwave_img): not same dimension"
		endif
	else
		Duplicate maskwave_img temp_img
	endif
	String Mask_combinedName="mask_fin"
	Make/O/N=(Dimsize(maskwave_gen,0),Dimsize(maskwave_gen,1)) $Mask_combinedName
	wave mask_con=$Mask_combinedName
	mask_con[][]=( ( (maskwave_gen[p][q]==1) && (temp_img[p][q]==0) )? 1 : 0)			//background of image == 0
	KillWaves temp_img
	return Mask_combinedName
END

//*****

// very important 030728
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

//******Prepareing filter **************************************************

Function V9_hist2Danal_VA()
	wave/z VecLengthWave=$StatnameProc("mag")
	wave/z DegWave=$StatnameProc("deg")
	wave/z ROIcoord=:analysis:W_ROIcoord2D
	Variable val_min1=ROIcoord[1][0]
	Variable val_max1=ROIcoord[1][1]
	Variable val_min2=ROIcoord[0][0]
	Variable val_max2=ROIcoord[0][1]
	Duplicate/O VecLengthWave maskVelAgl
	V9_GenerateMask2para(VecLengthWave,DegWave,maskVelAgl,val_min1,val_max1,val_min2,val_max2)	
	
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	if (ImageMask_ON)
//		wave/z maskwave_img=$V9_returnMaskedImg()
//		wave/z mask=$V9_combine2DMasksImg(maskVelAgl,maskwave_img)
//		Vec_V2DFilter_v2(mask)
//	else
		Vec_V2DFilter_v2(maskVelAgl)
		Print "ImageMask OFF!!"
//	endif
END

Function V9_hist2Danal_IntA()
	//wave/z VecLengthWave=$StatnameProc("mag")
	SVAR wavename_pref
//	NVAR LayerStart,LayerEnd
	string matrix3Dname="root:MAT"+wavename_pref
	wave/z matrix3D=$matrix3Dname
//commented out 030725
//	String firstframename=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)+"mx"
//	if (!waveexists($firstframename))
//		Make/O/N=(DimSize(matrix3D, 0),DimSize(matrix3D, 1)) $firstframename
//		//Variable slices=LayerEnd-Layerstart+1
//		Wave/z firstframe=$firstframename	
//		V9_ZprojectionFirstFrame(matrix3D,firstframe,LayerStart,LayerEnd)
//	else
//		Wave/z firstframe=$firstframename	
//	endif
	Wave/z firstframe=$(V9_Check4firstFrame(matrix3D))

	NVAR Unit
	Duplicate/O/R=[trunc(unit/2),(Dimsize(firstframe,0)-trunc(unit/2)-1)][trunc(unit/2),(Dimsize(firstframe,1)-trunc(unit/2)-1)] firstframe tempfirstframe
	wave/z DegWave=$StatnameProc("deg")
	if (!V9_checkSameDim2D(tempfirstframe,DegWave))
		abort "wave dimension error: V9_hist2Danal_IntA() tempfirstframe and Degwave"
	endif
	
	wave/z ROIcoord=:analysis:W_ROIcoord2D
	Variable val_min1=ROIcoord[1][0]
	Variable val_max1=ROIcoord[1][1]
	Variable val_min2=ROIcoord[0][0]
	Variable val_max2=ROIcoord[0][1]
	Duplicate/O tempfirstframe maskIntAgl
	V9_GenerateMask2para(tempfirstframe,DegWave,maskIntAgl,val_min1,val_max1,val_min2,val_max2)	
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	if (ImageMask_ON)
//		wave/z maskwave_img=$V9_returnMaskedImg()
//		wave/z mask=$V9_combine2DMasksImg(maskIntAgl,maskwave_img)
//		Vec_V2DFilter_v2(mask)
//	else
		Vec_V2DFilter_v2(maskIntAgl)
//		Print "ImageMask OFF!!"
//	endif
END

Function V9_hist2Danal_VInt()
	wave/z VecLengthWave=$StatnameProc("mag")
	SVAR wavename_pref
	//NVAR LayerStart,LayerEnd
	string matrix3Dname="root:MAT"+wavename_pref
	wave/z matrix3D=$matrix3Dname
// commented out 030725
//	String firstframename=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)+"mx"
//	if (!waveexists($firstframename))
//		Make/O/N=(DimSize(matrix3D, 0),DimSize(matrix3D, 1)) $firstframename
//		//Variable slices=LayerEnd-Layerstart+1
//		Wave/z firstframe=$firstframename	
//		V9_ZprojectionFirstFrame(matrix3D,firstframe,LayerStart,LayerEnd)
//	else
//		Wave/z firstframe=$firstframename	
//	endif
	Wave/z firstframe=$(V9_Check4firstFrame(matrix3D))
	NVAR Unit
	Duplicate/O/R=[trunc(unit/2),(Dimsize(firstframe,0)-trunc(unit/2)-1)][trunc(unit/2),(Dimsize(firstframe,1)-trunc(unit/2)-1)] firstframe tempfirstframe
	//wave/z DegWave=$StatnameProc("deg")
	if (!V9_checkSameDim2D(VecLengthWave,tempfirstframe))
		abort "wave dimension error: V9_hist2Danal_IntA() tempfirstframe and Degwave"
	endif
	
	wave/z ROIcoord=:analysis:W_ROIcoord2D
	Variable val_min1=ROIcoord[1][0]
	Variable val_max1=ROIcoord[1][1]
	Variable val_min2=ROIcoord[0][0]
	Variable val_max2=ROIcoord[0][1]
	Duplicate/O tempfirstframe maskVelInt
	V9_GenerateMask2para(VecLengthWave,tempfirstframe,maskVelInt,val_min1,val_max1,val_min2,val_max2)	
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	if (ImageMask_ON)
//		wave/z maskwave_img=$V9_returnMaskedImg()
//		wave/z mask=$V9_combine2DMasksImg(maskVelInt,maskwave_img)
//		Vec_V2DFilter_v2(mask)
//	else
		Vec_V2DFilter_v2(maskVelInt)
		Print "ImageMask OFF!!"
//	endif

END

Function V9_2Dhistanal_visualization()
	wave/z VX_filtered,VY_filtered
	averagingCore(VX_filtered,VY_filtered)
	wave/z VX_filteredav,VY_filteredav
	AddFilteredVec(VX_filteredav,VY_filteredav)
	NVAR L_isPosition=isPosition
	V_VelAngleCalc(1)
	V_showHists()
END

Function V9_2Dhistanal_do_original()
	//wave/z VX_filtered,VY_filtered
	//averagingCore(VX_filtered,VY_filtered)
	//wave/z VX_filteredav,VY_filteredav
	//AddFilteredVec(VX_filteredav,VY_filteredav)
	NVAR L_isPosition=isPosition
	//HistAnalCore(1,L_isPosition,0)
	HistAnalCore()
END
	
	
//******* R  O  I ******************************************************

//Function V9_setMaskImagefunc_switch(param)
//		variable param
//		String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
//		if (!DataFolderExists("Analysis"))
//			V9_initializeAnalysisFolder()
//		endif
//		NVAR ImageMask_ON=:analysis:ImageMask_ON
//		ImageMask_ON=param
//		//setdatafolder root:
//End

Function V9_ROI_histogram_2Dplot() //: GraphMarquee	commented out 030729
//	String igName= WMTopImageGraph() //imagecommon
	
//	if( strlen(igName) == 0 )
//		DoAlert 0,"No image plot found"
//		return 0
//	endif
	print "Velocity-Intensity ROI anal..."
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	GetMarquee left, bottom
	if (V_Flag == 0)
		Print "There is no marquee"
	else
		Variable windowtype=V9_checkWindowType(S_marqueeWin)
		if (windowtype>1)
		//if (cmpstr(S_marqueeWin,"windowname_shouldlookup")!=0)
			//NVAR Unit
			//if (Unit==3)
			//	V_Left=trunc(V_Left-1)
			//	V_Right=trunc(V_Right-1)
			//	V_bottom=trunc(V_bottom-1)
			//	V_top=trunc(V_top-1)
			//endif
			//wave/z Image=VX3D
			//-set full Z
			//variable up=DimSize(Image,2)-1
			//variable down=0
			NVAR isPosition
			//HistAnalCore()//1,isPosition,0) // is NOT filtered
			V_VelAngleCalc(0)
			if (!DataFolderExists("Analysis"))
				V9_initializeAnalysisFolder()
			endif			
			wave/z ROIcoord2D=:Analysis:W_ROIcoord2D
			wave/z ROIsize2D=:Analysis:W_ROIsize2D

					
			ROIcoord2D={{V_Left,V_bottom}, {V_right,V_top}}
			V9_correctROIcoord(ROIcoord2D,windowtype,isPosition)			
			ROIsize2D=ROIcoord2D[p][1]-ROIcoord2D[p][0]

			//NVAR V_windowtype=:Analysis:V_windowtype
			//V_windowtype=windowtype
			switch(windowtype)	
				case 2:		
					V9_hist2Danal_VA()
					print "Velocity-Angle filtering..."					
				break		
				case 3:		
					V9_hist2Danal_IntA()
					print "Angle-Intensity filtering..."
				break
				case 4:		
					V9_hist2Danal_VInt()
					print "Velocity-Intensity filtering..."
				break

				default:		
					print "did nothing"
			endswitch

		else
			setdatafolder "root:"
			abort "Wrong Window! Select ROI in 2D histogram"
		endif
		
		V9_2Dhistanal_visualization()
		
	endif
END

Function V9_2Dhist_clearROIdoALL()
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	if (!DataFolderExists("Analysis"))
		V9_initializeAnalysisFolder()
	endif			
	wave/z ROIcoord2D=:Analysis:W_ROIcoord2D
	wave/z ROIsize2D=:Analysis:W_ROIsize2D
	//NVAR V_windowtype=:Analysis:V_windowtype
	wave/z VX
	ROIcoord2D={{0,0}, {180,1}}
	ROIsize2D=ROIcoord2D[p][1]-ROIcoord2D[p][0]
	//V_windowtype=windowtype
END




Function V9_correctROIcoord(ROIcoord,windowtype,isPosition)
	wave ROIcoord
	variable windowtype,isPosition
	variable V_Left=RoiCoord[0][0]
	variable V_bottom=RoiCoord[1][0]
	variable V_right=RoiCoord[0][1]
	variable V_top=RoiCoord[1][1]
	
	switch (windowtype)
		case 2:			//Velocity - Angle
			if (isPosition)
				if (V_Left<-180)
					V_left=-180
				endif
				if (V_right>180)
					V_right=180
				endif
			else
				if (V_Left<0)
					V_left=0
				endif
				if (V_right>360)
					V_right=360
				endif
			endif
			if (V_bottom<0)
				V_bottom=0
			endif
			
			break
		case 3:			//Int-Angle
			if (isPosition)
				if (V_Left<-180)
					V_left=-180
				endif
				if (V_right>180)
					V_right=180
				endif
			else
				if (V_Left<0)
					V_left=0
				endif
				if (V_right>360)
					V_right=360
				endif
			endif
			if (V_bottom<0)
				V_bottom=0
			endif
			V_top=trunc(V_top)
			V_bottom=trunc(V_bottom)
			break	
		case 4:
			if (V_left<0)
				V_left=0
			endif		
			if (V_bottom<0)
				V_bottom=0
			endif
			V_left=trunc(V_left)
			V_right=trunc(V_right)
			break
		default:
			//
	endswitch
	ROIcoord={{V_Left,V_bottom}, {V_right,V_top}}
END


//---------------------------------030102
// for manual input of the intensity, speed and angle range
// initial version only for intensity and speed limiting

Function V9_filter_2Dplot_parainput() // : GraphMarquee
	variable intensityMIN,intensityMAX
	prompt intensityMIN, "intensity Minimum?"
	prompt intensityMAX, "intensity Maximum?"
	variable speedMIN,speedMAX
	prompt speedMIN, "speed Minimum?"
	prompt speedMAX, "speed Maximum?"
	DoPrompt "Enter Parameters for Vector Field Filtering",intensityMIN,intensityMAX,speedMIN,speedMAX
	if (V_flag)
		Abort "Processing Canceled"
	endif
		
	V9_VIfilter_2Dplot_core(intensityMIN,intensityMAX,speedMIN,speedMAX)
END


Function V9_VIfilter_2Dplot_core(intensityMIN,intensityMAX,speedMIN,speedMAX)
	variable intensityMIN,intensityMAX,speedMIN,speedMAX
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
//	GetMarquee left, bottom
//	if (V_Flag == 0)
//		Print "There is no marquee"
//	else
		Variable windowtype=4//V9_checkWindowType(CurrentPlot)
//		if (windowtype>1)

		NVAR isPosition
		HistAnalCore()//1,isPosition,0) // is NOT filtered
		if (!DataFolderExists("Analysis"))
			V9_initializeAnalysisFolder()
		endif			
		wave/z ROIcoord2D=:Analysis:W_ROIcoord2D
		wave/z ROIsize2D=:Analysis:W_ROIsize2D

					
		ROIcoord2D={{intensityMIN,speedMIN}, {intensityMAX,speedMAX}}
		V9_correctROIcoord(ROIcoord2D,4,isPosition)			
		ROIsize2D=ROIcoord2D[p][1]-ROIcoord2D[p][0]

		//NVAR V_windowtype=:Analysis:V_windowtype
		//V_windowtype=windowtype
//			switch(windowtype)	
//				case 2:		
//					V9_hist2Danal_VA()
//				break		
//				case 3:		
//					V9_hist2Danal_IntA()
//				break
//				case 4:		
		V9_hist2Danal_VInt()
//				break
//
//				default:		
//					//
//			endswitch

//		else
//			setdatafolder "root:"
//			abort "Wrong Window! Select ROI in 2D histogram"
//		endif
		
		V9_2Dhistanal_visualization()
		
//	endif
END
