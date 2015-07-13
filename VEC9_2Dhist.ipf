#pragma rtGlobals=1		// Use modern global access method.

//020829-30		Kota Miura
//020901 implement masking
//#include "Vec9_imageprocessing"
//#include "Vec9_2Dhist_anal"
//#include "VEC9_maskMeasurement"

//**** follwoing is the standalone, for menues
Function V9M_DoVeloAngl2DHist()
	String CurrentDataFolder=VEC9_Set_CurrentPlotDataFolder()
	//NVAR isPosition
	V_VelAngleCalc(0)//HistAnalCore()//1,isPosition,0) // is NOT filtered	
	V9_DoVeloAngl2DHist()
	//V9_2Dhistanal_visualization()
	setdatafolder "root:"
END 

Function V9M_DoIntAngl2DHist()
	String CurrentDataFolder=VEC9_Set_CurrentPlotDataFolder()
	NVAR isPosition
	V_VelAngleCalc(0)//HistAnalCore()//1,isPosition,0) // is NOT filtered	
	V9_DoIntAngl2DHist()
	//V9_2Dhistanal_visualization()	
	setdatafolder "root:"
END 

Function V9M_DoVeloInt2DHist()
	String CurrentDataFolder=VEC9_Set_CurrentPlotDataFolder()
	NVAR isPosition
	V_VelAngleCalc(0)//HistAnalCore()//1,isPosition,0) // is NOT filtered	
	V9_DoVeloInt2DHist()
	//V9_2Dhistanal_visualization()	
	setdatafolder "root:"
END 

Function/S VEC9_Set_CurrentPlotDataFolder()
	string CurrentWindow
	if (cmpstr(WinName(0,1), "")==0)
		if (cmpstr(WinName(0,4069), "")==0)
			abort "There is no Surface Plot, no Histograms nor Colorcoded Z"
		else
			CurrentWindow=WinName(0,4096)
		endif
	else
		CurrentWindow=WinName(0,1)
	endif
	wave/z currentPlot=WaveRefIndexed(CurrentWindow,0,1)
	String currentFolder=GetWavesDataFolder(currentPlot,0)
	if (cmpstr(currentFolder,"")==0) 
		currentFolder=V9_GetImageWave(currentWindow)  
	endif
	//print "going to"+currentFolder
	SetDataFolder "root:"+currentFolder
	return currentFolder
END
 
Function/S V9_GetImageWave(grfName)			//copy of V9_...
	String grfName							// use zero len str to speicfy top graph

	String s= ImageNameList(grfName, ";")
	Variable p1= StrSearch(s,";",0)
	if( p1<0 )
		return ""			// no image in top graph
	endif
	s= s[0,p1-1]
	Wave w= ImageNameToWaveRef(grfName, s)
	return GetWavesDataFolder(w,0)		// full path to wave including name
end


//***********followings are the core, within target datafolder
Function V9_DoVeloAngl2DHist()
	Variable param=0
	String RadWavename=StatnameProc("rad")
	String VecLengthWavename=StatnameProc("mag")
	Wave/Z RadWave=$RadWavename
	Wave/Z VecLengthWave=$VecLengthWavename
	
			//V3_stat_Velocity()
			//V3_stat_Angle_absolute()
			//V3_stat_AngleXYZ_absolute()	
	Variable binnumberX=36
	Variable binnumberY=40
	Make/O/N=(binnumberX,binnumberY) Hist2D_VA
	V9_angleX2DHist(RadWave,VecLengthWave,Hist2D_VA)
	String presentWindows=WinList((V9_2DHistWinName(param)+"*"), ";", "" )		
	if (WhichListItem(V9_2DHistWinName(param), presentWindows)==(-1))		
		V9_Display_2Dhisto(Hist2D_VA,param)
	else
		 //V9_2dhistTextInfo(V9_2DHistWinName(param))
	endif
	DoWindow/F $V9_2DHistWinName(param)
	NVAR isPosition
//	if (isPosition)
//		SetAxis bottom -190,190 
//	else
//		SetAxis bottom -10,370 
//	endif	
END 

Function V9_DoIntAngl2DHist()			//modified 020905
	Variable param=1
	wave src3Dwave=$V9_Original3Dwave()	
	String RadWavename=StatnameProc("rad")
	String imageWavename=V9_Tproject_image(src3Dwave,V9_getTProjectionMethod())
//	String imageWavename="MATs18fp3_8b_zPro"

	Wave/Z RadWave=$RadWavename
	Wave/Z imagewave=$ImageWavename
	NVAR unit
//	variable imagestarts=unit-2
//	Duplicate/O/R=[imagestarts,*][imagestarts,*] imagewave tempImg
	Variable sizeshift=trunc(unit/2)
	Duplicate/O/R=[sizeshift,(DimSize(imagewave,0)-sizeshift-1)][sizeshift,(DimSize(imagewave,1)-sizeshift-1)] imagewave tempImg
	Variable binnumberX=36
	Variable binnumberY=40
	Make/O/N=(binnumberX,binnumberY) Hist2D_IntA
	V9_angleX2DHist(RadWave,tempImg,Hist2D_IntA)
	killwaves tempImg
	String presentWindows=WinList((V9_2DHistWinName(param)+"*"), ";", "" )		
	if (WhichListItem(V9_2DHistWinName(param), presentWindows)==(-1))		
		V9_Display_2Dhisto(Hist2D_IntA,param)
	else
		 //V9_2dhistTextInfo(V9_2DHistWinName(param))
	endif
	DoWindow/F $V9_2DHistWinName(param)	
//	NVAR isPosition
//	if (isPosition)
//		SetAxis bottom -190,190 
//	else
//		SetAxis bottom -10,370 
//	endif	

END 

Function V9_DoVeloInt2DHist()		//modified 020905
	Variable param=2
	wave src3Dwave=$V9_Original3Dwave()
	String VecLengthWavename=StatnameProc("mag")
	String imageWavename=V9_Tproject_image(src3Dwave,V9_getTProjectionMethod())		//1=maxim intensity projection
	Wave/Z VecLengthWave=$VecLengthWavename
	Wave/Z imagewave=$ImageWavename
	//print ImageWavename
	NVAR unit
//	variable imagestarts=unit-2
//	Duplicate/O/R=[imagestarts,*][imagestarts,*] imagewave tempImg
	Variable sizeshift=trunc(unit/2)
	Duplicate/O/R=[sizeshift,(DimSize(imagewave,0)-sizeshift-1)][sizeshift,(DimSize(imagewave,1)-sizeshift-1)] imagewave tempImg
	Variable binnumberX=40
	Variable binnumberY=40
	Make/O/N=(binnumberX,binnumberY) Hist2D_VInt
	V9_general2DHist(tempImg,VecLengthWave,Hist2D_VInt)	
	//killwaves tempImg
	String presentWindows=WinList((V9_2DHistWinName(param)+"*"), ";", "" )		
	if (WhichListItem(V9_2DHistWinName(param), presentWindows)==(-1))		
		V9_Display_2Dhisto(Hist2D_VInt,param)
	else
		 //V9_2dhistTextInfo(V9_2DHistWinName(param))
	endif

	DoWindow/F $V9_2DHistWinName(param)	
END 


//*******************************************************
Function V9_angleX2DHist(srcWaveANG2D,srcWaveY2D,dest2Dwave)	
	Wave srcWaveANG2D,srcWaveY2D,dest2Dwave			//angle wave should be a rad. destination should be x-scaled already
	if (!V9_checkSameDim2D(srcWaveANG2D,srcWaveY2D))
		abort "wave dimension error: V9_angleX2DHist(srcWaveANG2D,srcWaveY2D,dest2Dwave) :srcWaveANG2D,srcWaveY2D"
	endif
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	SVAR/z S_maskingName=:analysis:S_maskingName
//	if (ImageMask_ON)
////		wave/z maskwave_img=$V9_returnMaskedImg()
////		S_maskingName=NameofWave(maskwave_img)
//		S_maskingName=V9_returnMaskedImg()
////	else
////		wave/z maskwave_img=$S_maskingName
//	endif
//	wave srcWaveANG=$V9_2DwaveTo1D(srcWaveANG2D,maskwave_img)
//	wave srcWaveY=$V9_2DwaveTo1D(srcWaveY2D,maskwave_img)
	wave srcWaveANG=$V9_2DwaveTo1D(srcWaveANG2D)//,maskwave_img)
	wave srcWaveY=$V9_2DwaveTo1D(srcWaveY2D)//,maskwave_img)

	Variable nbins=DimSize(dest2Dwave,0)
	Variable mbins=DimSize(dest2Dwave,1)
	Variable rows=DimSize(srcWaveANG,0)
	
	wavestats/Q srcWaveY
	Variable rangeY=V_max-V_min
	Variable minY=V_min
	Variable i=0
	Variable index1,index2
	Variable V3ang,V3_Y
	Variable twopi=2*pi
	//Variable piBy2=pi //pi/2
	dest2Dwave=0
	NVAR isPosition		//if the reference point is there 0 absolute, 1 relative
	do
			V3ang=srcWaveANG[i]		// derive (in radians [0-2pi]) from srcWave
			V3_Y=srcWaveY[i]	// derive (in radians [0-pi/2]) from srcWave
			if (numtype(V3ang)==0 && numtype(V3_y)==0)
				//if (numtype(V3ang)!=0)
					//V3ang=0
				//else
					//if (numtype(V3theta)!=0)
					//	V3_Y=0
					//endif
				//endif							
				if (isPosition==1)
					index1=nbins*(V3ang+pi)/twopi		//relative angle: --180 -  180
				else
					index1=nbins*V3ang/twopi			//absolute angle 0- 360
				endif
				index2=mbins*(V3_Y-minY)/rangeY
				dest2Dwave[index1][index2]=dest2Dwave[index1][index2]+1
			endif
			i+=1
	while(i<rows)
	if (isPosition==1)
		SetScale/P x -180,(360/nbins),"", dest2Dwave //relative
	else
		SetScale/P x 0,(360/nbins),"", dest2Dwave	//absolute
	endif	
	SetScale/P y minY,(rangeY/mbins),"", dest2Dwave	
	Killwaves srcWaveANG,srcWaveY
End

Function V9_general2DHist(srcWaveX2D,srcWaveY2D,dest2Dwave)	
	Wave srcWaveX2D,srcWaveY2D,dest2Dwave			//destination2D should be x-scaled already
	if (!V9_checkSameDim2D(srcWaveX2D,srcWaveY2D))
		abort "wave dimension error: V9_general2DHist(srcWaveX2D,srcWaveY2D,dest2Dwave) :srcWaveX2D,srcWaveY2D"
	endif
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	SVAR/z S_maskingName=:analysis:S_maskingName
//	if (ImageMask_ON)
////		wave/z maskwave_img=$V9_returnMaskedImg()
////		S_maskingName=NameofWave(maskwave_img)
//		S_maskingName=V9_returnMaskedImg()
////	else
////		wave/z maskwave_img=$S_maskingName
//	endif
//	wave srcWaveX=$V9_2DwaveTo1D(srcWaveX2D,maskwave_img)
//	wave srcWaveY=$V9_2DwaveTo1D(srcWaveY2D,maskwave_img)
	wave srcWaveX=$V9_2DwaveTo1D(srcWaveX2D)//,maskwave_img)
	wave srcWaveY=$V9_2DwaveTo1D(srcWaveY2D)//,maskwave_img)
	Variable nbins=DimSize(dest2Dwave,0)
	Variable mbins=DimSize(dest2Dwave,1)
	Variable rows=DimSize(srcWaveX,0)

	variable grayscale=256			//030120
	//wavestats/Q srcWaveX
	//Variable rangeX=V_max-V_min
	//Variable minX=V_min
	Variable rangeX=(Grayscale)*1.1	//030120
	Variable minX=0					//030120
	wavestats/Q srcWaveY
	Variable rangeY=(V_max-V_min)*1.1
	Variable minY=V_min
	//printf "rangeX %d ; rangey %d",rangex,rangeY
	if ( (rangeX==0) || (rangeY==0))
		printf "range X (%s): %d, rangeY (%s) %d\r",nameofwave(srcwaveX),rangeX,nameofwave(srcwaveY),rangey
		abort "V9_general2DHist: none sense ranges for the source waves"
	endif
	Variable i=0
	Variable index1,index2
	Variable V3_X,V3_Y

	dest2Dwave[][]=0
	do
			V3_X=srcWaveX[i]		
			V3_Y=srcWaveY[i]	
			if (numtype(V3_X)==0 && numtype(V3_y)==0)
				index1=nbins*(V3_X-minX)/rangeX				
				//index1=round(nbins*(V3_X)/grayscale)
				index2=mbins*(V3_Y-minY)/rangeY
				dest2Dwave[index1][index2]+=1
//				printf "Index1 :=%d   ",index1	
//				printf "Index2 :=%d\r",index2		
			endif
			i+=1
	while(i<rows)
	SetScale/P x (minX+(rangeX/nbins)/2),(rangeX/nbins),"", dest2Dwave	
//	SetScale/P x 0,(257/nbins),"", dest2Dwave	
	SetScale/P y minY,(rangeY/mbins),"", dest2Dwave

	Killwaves srcWaveX,srcWaveY		
End

//*********************************************************************
Function/S V9_2DwaveTo1D(srcWave2D)//,maskwave_img)			//put masking filter here!!!!!!!!!!!!!!!!
	wave srcWave2D//,maskwave_img
	Variable X_size=Dimsize(srcWave2D,0)
	Variable Y_size=Dimsize(srcWave2D,1)
	String New1Dwavename=NameofWave(srcWave2D)+"_tem1D"
	Duplicate/O srcWave2D $New1Dwavename
	wave New1Dwave=$New1Dwavename
	if (!DataFolderExists("Analysis"))
		V9_initializeAnalysisFolder()
	endif	
// commenteed out 030730
//	NVAR ImageMask_ON=:analysis:ImageMask_ON
//	if (ImageMask_ON)
//		//wave/z maskwave_img=$V9_returnMaskedImg()	
//		SVAR maskwave_imgName=:analysis:S_maskingName
//		wave/z maskwave_img=$maskwave_imgName
//		V9_Mask2D(New1Dwave,maskwave_img,New1Dwave,0,255)
//		printf "filtering %s\r",New1Dwavename	
//	endif
	redimension/N=(X_size*Y_size)	$New1Dwavename
	//printf "2D to 1D converted:  %s\r",New1Dwavename
	return New1Dwavename
END	

Function V9_Mask2D(srcwave2D,maskwave2D,destwave2D,maskFront,maskBack)		//020901
// need a thresholded binary 8bit image for this purpose
	wave srcwave2D,maskwave2D,destwave2D
	variable maskFront,maskBack
	NVAR unit
	variable srcX=Dimsize(srcwave2D,0)
	variable srcY=Dimsize(srcwave2D,1)
	variable maskX=Dimsize(maskwave2D,0)
	variable maskY=Dimsize(maskwave2D,1)
	if ((maskX-srcX)!=(unit-1) || (maskY-srcY)!=(unit-1))
		abort "V9_Mask2D():  Mask image does not match the size...RE-DO it!"
	endif
	
	wavestats/Q maskwave2D
	if ( (V_max==maskFront || V_max==maskback) && (V_min==maskFront || V_min==maskback)  )
		//Duplicate/O srcWave2D ,destwave2D
		//destwave2D[][]=0
		destwave2D[][]=((maskwave2D[p+1][q+1]==maskFront) ? srcWave2D[p][q] : Nan)
	else
		abort "Mask image could be non-8bit image"
	endif
END


//***************************************Display
Function V9_Display_2Dhisto(src2Dwave,param)
	wave src2Dwave
	variable param
	string labelX=V9_2DHistWinLabelX(param)
	string labelY=V9_2DHistWinLabelY(param)
	string src2DwaveName=NameofWave(src2Dwave)
	Display /W=(0,320,300,600);AppendImage src2Dwave
	ModifyGraph height={Plan,1,left,bottom}
	AppendMatrixContour src2Dwave 
	DoUpdate
	ModifyContour $src2DwaveName rgbLines=(65535,65535,65535)
	ModifyContour $src2DwaveName autoLevels={*,*,3}
	ModifyContour $src2DwaveName labelBkg=1,labelFSize=6	
	DoUpdate
	Label left labelY
	Label bottom labelX
	ModifyGraph width=150,height=150
//	if (param==0 || param==1)
//		NVAR isPosition
//		if (isPosition)
//			SetAxis bottom -190,190 
//		else
//			SetAxis bottom -10,370 
//		endif
//	endif	
	ModifyImage $src2DwaveName ctab= {*,*,BlueRedGreen,0}
	Colorscale/E/A=LC/F=0/N=colortable image=$src2Dwavename
	ColorScale/C/N=colortable side=2,width=10//,image=$src2Dwavename
	ColorScale/C/N=colortable fsize=7	

	//ColorScale/C/N=colortable/X=0/Y=0 trace=VY3D1D
//	ColorScale/C/N=colortable fsize=8
//	Button reset2Dhist proc=xV9_reset2DhistButtonProc,title="reset"
//	Button reset2Dhist pos={30,10},size={70,15}
	Button reset2Dhist proc=xV_showRange2DhistProc,title="show range"
	Button reset2Dhist pos={15,5},size={75,15}	
//	Button imgMask2Dhist proc=xV9_imgMask2DhistButtonProc,title="Img Mask"		//comented out 030730
//	Button imgMask2Dhist pos={30,25},size={50,15}
	Button imgMask2Dhist proc=xV_hideRange2DhistProc,title="hide range"
	Button imgMask2Dhist pos={15,20},size={75,15}
	
	DoWindow/C $V9_2DHistWinName(param)
	//V9_2dhistTextInfo(V9_2DHistWinName(param))
END

// following unused from 030730
//Function V9_2dhistTextInfo(Histwin)
//	string histwin
//	if (DataFolderExists("Analysis"))
//		NVAR ImageMask_ON=:analysis:ImageMask_ON
//		if (ImageMask_ON)
//			SVAR S_maskingName=:analysis:S_maskingName
//			TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"Image Mask: "+S_maskingName//new 020902	
//		else
//			TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"No Image Mask Applied"//new 020902	
//		endif
//	else
//		TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"No Image Mask Applied"//new 020902	
//	endif
//	TextBox/W=$HistWin/C/N=MaskInfo/A=LB/F=0/X=-55.00/Y=-20.00
//END



Function/S V9_2DHistWinLabelX(param)
	Variable Param	// 0=2DVelocity vs angle, 1=2D Intensity vs angle, 2=Velocity vs Intensity
	String labelX="_Angle"
	Switch (param)
		Case 0:
			labelX="Angle"
			break
		case 1:
			labelX="Angle"
			break
		case 2:
			labelX="Pixel Intensity"
			break
		default:
			break
	endswitch
	Return labelX
END

Function/S V9_2DHistWinLabelY(param)
	Variable Param	// 0=2DVelocity vs angle, 1=2D Intensity vs angle, 2=Velocity vs Intensity
	String labelY="_Angle"
	Switch (param)
		Case 0:
			labelY="Velocity"
			break
		case 1:
			labelY="Pixel Intensity"
			break
		case 2:
			labelY="Velocity"
			break
		default:
			break
	endswitch
	Return labelY
END

//************* controls

// 030730 modified
Function xV9_reset2DhistButtonProc(ctrlName) : ButtonControl
	String ctrlName
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	//V9_setMaskImagefunc_switch(0)		//commented out 030730
	Variable windowtype=V9_checkWindowType(WinName(0,1))
	if (windowtype>1)	
			switch(windowtype)	
				case 2:		
					V9M_DoVeloAngl2DHist()//V9_hist2Danal_VA()
				break		
				case 3:		
					V9M_DoIntAngl2DHist()//V9_hist2Danal_IntA()
				break
				case 4:		
					V9M_DoVeloInt2DHist()//V9_hist2Danal_VInt()
				break

				default:		
					//
			endswitch

	else
		setdatafolder "root:"
		abort "Wrong Window! "
	endif	
	setdatafolder "root:"
END


//Function tempFunc()
//	Button xV9_Update2DhistButton,pos={620,5},size={50,20},proc=xVecDoitButtonProc,title="clear ROI"
//END


// 030730 commented out
//Function xV9_imgMask2DhistButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
//	V9_setMaskImagefunc_switch(1)
//	Variable windowtype=V9_checkWindowType(WinName(0,1))
//	if (windowtype>1)	
//			switch(windowtype)	
//				case 2:		
//					V9M_DoVeloAngl2DHist()//V9_hist2Danal_VA()
//				break		
//				case 3:		
//					V9M_DoIntAngl2DHist()//V9_hist2Danal_IntA()
//				break
//				case 4:		
//					V9M_DoVeloInt2DHist()//V9_hist2Danal_VInt()
//				break
//
//				default:		
//					//
//			endswitch
//
//	else
//		setdatafolder "root:"
//		abort "Wrong Window! "
//	endif	
//	setdatafolder "root:"
//END


//030730
// instead of the above function "xV9_imgMask2DhistButtonProc(ctrlName) : ButtonControl"
// show/hide ROI will be the button function

Function xV_showRange2DhistProc(ctrlName) : ButtonControl
	String ctrlName
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	V_ShowCurrentROI()
	setdatafolder "root:"
END

Function xV_hideRange2DhistProc(ctrlName) : ButtonControl
	String ctrlName
	V_Cleardrawings()
END