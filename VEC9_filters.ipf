#pragma rtGlobals=1		// Use modern global access method.

//030725 Kota Miura
//copied the whole thing from VEC3


// 0 filter2D 1 anglefilter, 2 velfilter, 3 intfilter
//030506
//use "V3_setFilter(type,minV,maxV)" for filtering!
//mazbe its better not creating specific filters. treat only one filter (memory wise).
//040513
// changed the single-pixel filtering to percent.

Function V9_createFilterCore(type)		//only type 0 is used
	variable type
	wave/z src2Dwave=::VX
	duplicate/O src2Dwave filter
	filter=1			//select all
	switch(type)	
		case 0:
//			if (waveexists(filter2D))			//use only this "filter3D"
//				Killwaves filter2D
//			endif
			Duplicate/o filter filter2D
			killwaves filter 
			break						
		case 1:
			if (waveexists(anglefilter))
				Killwaves anglefilter
			endif
			rename filter anglefilter 
			break						
		case 2:
			if (waveexists(velfilter))
				Killwaves velfilter
			endif
			rename filter velfilter 
			break						
		case 3:
			if (waveexists(intfilter))
				Killwaves intfilter
			endif
			rename filter intfilter 
			break						
		default:			
			killwaves filter
	endswitch
END
	
Function V9_createFilter(type)
	variable type
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	SetDataFolder :GraphParameters	
		V9_createFilterCore(type)	
	SetDataFolder curDF
END

Function/s V9_returnFiltername(type)		//only type 0 is currently used
	variable type
	string filtername
	switch (type)
		case 0:
			filtername="filter2D"
			break
		case 1:
			filtername="anglefilter"
			break
		case 2:
			filtername="velfilter"
			break
		case 3:
			filtername="intfilter"
			break
		case 4:
			filtername="ROIfilter"
			break			
	endswitch
	return filtername
END

Function/s V9_returnSrcwave(type)
	variable type
	string srcwavename="dummy"
	switch (type)
//		case 0:
//			filtername="filter3D"
//			break
		case 1:
			srcwavename=StatnameProc("deg")//"Vec_degPhai"
			break
		case 2:
			srcwavename=StatnameProc("mag")//"Vec_deg"			
			break
		case 3:
			//these lines should be sophisticated
			SVAR wavename_pref
			string matrix3Dname="root:MAT"+wavename_pref
			wave/z matrix3D=$matrix3Dname
			srcwavename=V9_Check4firstFrame(matrix3D)
			break
	endswitch	
	return srcwavename
END


Function V9_setFilterLM(type,minV,maxV)	//takes less memory 030523 //modified for the vec9 030727
	variable	type,minV,maxV
	//String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	//SetDataFolder :GraphParameters		
	wave/z filter=$(":GraphParameters:"+V9_returnFiltername(0))//(type)			030523 create only to the filter3D
	wave/z src2Dwave=$(V9_returnSrcwave(type))

	variable offsetX=0
	variable offsetY=0
	NVAR unit//=::unit
	if (type==3 && unit==3)		// if filtering uses image intensity (type 4)
		offsetX=1
		offsetY=1	
	endif
	
	NVAR G_checkAngleNOT=:GraphParameters:G_checkAngleNOT		//030729		for introducing "Not in this Angle range" filter
	if ((type==1) && (G_checkAngleNOT==1))		//030729	
		filter[][]=( ( ((minV>src2Dwave[offsetX+p][offsetY+q]) || (src2Dwave[offsetX+p][offsetY+q]>maxV)) && (filter[p][q]==1) )? 1: NaN)		//030729		
	else
		filter[][]=( ( (minV<src2Dwave[offsetX+p][offsetY+q]) && (src2Dwave[offsetX+p][offsetY+q]<maxV) && (filter[p][q]==1) )? 1: NaN)			
	endif
	///SetDataFolder curDF
END


Function V9_clearFilters()				//from current folder
	variable i
	for (i=1;i<5;i+=1)
		wave/z specificFilter=$(":GraphParameters:"+V9_returnFiltername(i))
		specificFilter=1
	endfor
END

Function V9_clearFilter2D()				//from current folder
		wave/z Filter2D=:GraphParameters:Filter2D
		Filter2D=1
END

//------------------------------------------- ROI filtering -------------------------------------------------



Function V9_createROIfilterCore()
	wave/z src2Dwave=::VX
	duplicate/O src2Dwave ROIfilter
	ROIfilter=1			//select all
END


Function V9_createROIfilter()
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	SetDataFolder :GraphParameters	
		V9_createROIfilterCore()
	SetDataFolder curDF
END

Function V9_setROIfilterCore() //030726
	wave/z ROIfilter
	wave/z W_ROIcoord
	//{{V_Left,V_bottom}, {V_right,V_top}}
	variable Left=W_ROIcoord[0][0]
	variable Bottom=W_ROIcoord[1][0]
	variable Right=W_ROIcoord[0][1]
	variable Top=W_ROIcoord[1][1]
	ROIfilter[][]=(((Left<p)&&(p<Right)&&(bottom<q)&&(q<top)) ? 1 : NaN)
END


Function V9_setROIfilter()		//030726
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	SetDataFolder :GraphParameters	
		V9_setROIfilterCore()
	SetDataFolder curDF
END

Function V9_applyROIfilter()
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	SetDataFolder :GraphParameters	
	V9_setROIfilterCore() 		
	wave/z ROIfilter
	wave/z filter=$V9_returnFiltername(0)//(type)			030523 create only to the filter3D

	variable offsetX=0
	variable offsetY=0
	NVAR unit=::unit
	if (unit==3)		// if filtering uses image intensity (type 4)
		offsetX=1
		offsetY=1	
	endif
	filter[][]=( ((ROIfilter[offsetX+p][offsetY+q]==1) && (filter[offsetX+p][offsetY+q]==1)) ? 1: NaN)			
	SetDataFolder curDF	
END

Function Store_ROI() : GraphMarquee
	V_Store_ROIcore()
END

Function V_Store_ROIcore()
	String curDF=GetDataFolder(1)	
	SetToTopImageDataFolder()	//setdatafolder	
	variable graph_type=V9_checkWindowType(WinName(0,1))
	if (graph_type==1)	
		GetMarquee left, bottom
		if (V_Flag == 0)
			Print "There is no marquee"
			return 0
		else	
			V_ROI_limitTOrange_Horizon()
			V_ROI_limitTOrange_Vert()
			NVAR unit
			if (Unit==3)
				V_Left=trunc(V_Left-1)
				V_Right=trunc(V_Right-1)
				V_bottom=trunc(V_bottom-1)
				V_top=trunc(V_top-1)
			endif // otherwise, unit=2 and can be remained same
			wave/z W_ROIcoord=:GraphParameters:W_ROIcoord
			wave/z W_ROIsize=:GraphParameters:W_ROIsize
			W_ROIcoord={{V_Left,V_bottom}, {V_right,V_top}}
			W_ROIsize=W_ROIcoord[p][1]-W_ROIcoord[p][0]
			V_ShowCurrentROI()
			return 1	
		endif
	else
		abort "ROI should be drawn only in a VectorField"
		return 0
	endif
	SetDataFolder curDF
END

//***** ROI utilities ****************************************

Function V_ROI_limitTOrange_Horizon()		//030527 //030729 copied from Vec3
	GetAxis/Q bottom
	NVAR/z V_Left,V_Right//,V_min,V_max
	V_Left=(V_Left<V_min ? V_min : V_Left)
	V_Right=(V_Right>V_max ? V_max : V_Right)
END

Function V_ROI_limitTOrange_Vert()			//030527 //030729 copied from Vec3
	GetAxis/Q left
	NVAR/z V_Bottom,V_Top//,V_min,V_max
	V_Bottom=(V_Bottom<V_min ? V_min : V_Bottom)
	V_Top=(V_Top>V_max ? V_max : V_Top)
END

Function V_DrawRoi(x0,y0,x1,y1)//,roiname)		//030527 //030729 copied & modified Vec3
	Variable x0,y0,x1,y1
	SetDrawLayer UserFront
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,16384)
	SetDrawEnv fillfgc= (65280,65280,16384),fillpat= 0,linethick= 2.00
	DrawRect x0,y0,x1,y1
END
Function V_Cleardrawings()		//030729 copied & modified Vec3
	SetDrawLayer/K UserFront
END

Function V_ShowCurrentROI()		//030729 copied & modified Vec3
	String curDF=GetDataFolder(1)	
	SetToTopImageDataFolder()	//setdatafolder	
	variable graph_type=V9_checkWindowType(WinName(0,1))
	SetDrawLayer/K UserFront
	SetDrawLayer UserFront
	switch(graph_type)	
		case 1:		
			wave/z ROIcoord= :GraphParameters:W_ROIcoord
			V_DrawRoi(ROIcoord[0][0],ROIcoord[1][0],ROIcoord[0][1],ROIcoord[1][1])
			break	
		case 2:		//vel-angle		
			wave/z vel= :GraphParameters:W_VelRange
			wave/z angle= :GraphParameters:W_AngleRange
			V_DrawRoi(angle[0],vel[0],angle[1],vel[1])			
			break
		case 3:		//Int-angle
			wave/z int= :GraphParameters:W_IntRange
			wave/z angle= :GraphParameters:W_AngleRange
			V_DrawRoi(angle[0],int[0],angle[1],int[1])							
			break
		case 4:		//vel-Int
			wave/z vel= :GraphParameters:W_VelRange
			wave/z int= :GraphParameters:W_IntRange
			V_DrawRoi(int[0],vel[0],int[1],vel[1])						
			break

		default:		
			abort "Not an apporopriate graph type"
	endswitch
	SetDataFolder curDF
END


//********************************************************
Function V9_switchANGLErange()		// 030727 for switching the angle range 0-360 and -180-+180
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	NVAR isPosition
	NVAR G_checkAngleMAX=:GraphParameters:G_checkAngleMAX
	NVAR G_checkAngleMIN=:GraphParameters:G_checkAngleMIN
	wave/z AngleRange=:GraphParameters:W_AngleRange
	if (isPosition==0)
		G_checkAngleMAX=360
		G_checkAngleMIN=0
		AngleRange[0]=((AngleRange[0]<0) ? 0 : AngleRange[0])
		AngleRange[1]=((AngleRange[1]>360) ? 360 : AngleRange[1])
	else
		G_checkAngleMAX=180
		G_checkAngleMIN=-180
		AngleRange[0]=((AngleRange[0]<-180) ? -180 : AngleRange[0])
		AngleRange[1]=((AngleRange[1]>180) ? 180 : AngleRange[1])
	endif
	String WindowMatching=Winlist("FilterPanel",";","")
	if (WhichListItem("FilterPanel", WindowMatching)!=(-1))
		SetVariable setvarAngle_min limits={G_checkAngleMIN,G_checkAngleMAX,5},win=FilterPanel
		SetVariable setvarAngle_max limits={G_checkAngleMIN,G_checkAngleMAX,5},win=FilterPanel
	endif
	SetDataFolder curDF
END

Function V_updateRangeDrawing()
	SetToTopImageDataFolder()
	NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
	NVAR/z G_checkFiltering=:GraphParameters:G_checkFiltering
	V9_refreshCheckFiltering()	
	variable i
	if (G_checkFiltering>1)
		for (i=8;i<11;i+=1)
			 if (V_WindowExists(i)==1)
			 	DoWindow/F $HistWinName(i)
			 	V_ShowCurrentROI()
			 endif
		endfor
	endif
	if ((G_checkRoi==1) && (V_VecWindowExists()==1))
		DoWindow/F $VectorFieldWindowName()
	 	V_ShowCurrentROI()
	endif
	
END

Function V9_updateRangeDrawButton(ctrlName) : ButtonControl
	String ctrlName
	V_updateRangeDrawing()
END


//********                  MASK 030727               ***********************************
Function V9_checkMaskImg(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	//String ImageName
	SetToTopImageDataFolder()	
	//SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName	
	if (checked==	1)
		V9_returnMaskedImgV2()
		CheckBox FP_checkImageMask title=("Mask: "+S_ImgMaskName),win=FilterPanel
	else
		CheckBox FP_checkImageMask title="Mask",win=FilterPanel
	endif
	//DrawText/W=FilterPanel 165,180,imagename
END


Function/S V9_returnMaskedImgV2()			//020901 //V2 030726 from current folder

	String curDF=GetDataFolder(1)
	SetDataFolder "root:"
	String maskList=WaveList("MSK*",";","")
	String	maskWaveName
	if (cmpstr(masklist,"")!=0)
		prompt	maskWaveName, "which image?", popup maskList  
		DoPrompt "Select a bianry tiff Image for masking", maskWaveName
	//	wave maskwave=$maskWaveName
	//	VEC_MaskedStat(maskwave)
		maskWaveName="root:"+maskWaveName

		// added for showing it in the graph
	//	if (!DataFolderExists("Analysis"))		
	//		V9_initializeAnalysisFolder()
	//	endif
	else
		maskWaveName="NoApporopriateImage"
	endif
	SetDataFolder curDF
	SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName
	S_ImgMaskName=maskWaveName	
	return maskWaveName
END


Function V_applyImgMask()

	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	SetDataFolder :GraphParameters	
	SVAR S_ImgMaskName//=:GraphParameters:S_ImgMaskName
	wave ImgMask=$S_ImgMaskName		
	wave/z filter=$V9_returnFiltername(0)//(type)			030523 create only to the filter3D
	NVAR unit=::unit
	variable srcX=Dimsize(filter,0)
	variable srcY=Dimsize(filter,1)
	variable maskX=Dimsize(ImgMask,0)
	variable maskY=Dimsize(ImgMask,1)
	
//	if (   ((maskX-srcX)!=(maskX-trunc(maskX/unit))) || ((maskY-srcY)!=(maskY-trunc(maskY/unit))) )
	if (   ((maskX-srcX)!=(unit-1)) || ((maskY-srcY)!=(unit-1))  )
		Print "Mask image does not match the size...RE-DO it!"
	else
		variable offsetX=0
		variable offsetY=0
		NVAR unit=::unit
		if (unit==3)		// if filtering uses image intensity (type 4)
			offsetX=1
			offsetY=1	
		endif
		//V_Convrt0ToNaN(ImgMask)
		filter[][]=( ((ImgMask[offsetX+p][offsetY+q]==1) && (filter[p][q]==1)) ? 1: NaN)			
		//V_ConvrtNaNTo0(ImgMask)
	endif
	SetDataFolder curDF	

END


//**** Reomove Single Pixel Brightspots (which should be noise) 030812
// works in the current folder
Function V_applySinglePixRemovefilter()		
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	NVAR range=:GraphParameters:G_ContinuumRange
	//SetDataFolder :GraphParameters	
	//V9_setROIfilterCore()
//	wave/z singlepixFilter=:GraphParameters:singlepixFilter
//	if (waveexists(singlepixFilter)==0)	
		wave  img_w=$V9_returnSrcwave(3)	
		V_filterSinglePixSignal(img_w,range)
		wave/z singlepixFilter=:GraphParameters:singlepixFilter		
//	endif
	wave/z filter=$(":GraphParameters:"+V9_returnFiltername(0))//$V9_returnFiltername(0)//(type)			030523 create only to the filter3D

	filter[][]=( ((singlepixFilter[p][q]==1) && (filter[p][q]==1)) ? 1: NaN)			
	SetDataFolder curDF	
END

Function V9_checkSinglePixRemove(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	SetToTopImageDataFolder()	
	NVAR G_ContinuumRange=:GraphParameters:G_ContinuumRange	
	if (checked==1)
		SetVariable setSinglePixRange win=FilterPanel,disable=0
	else
		SetVariable setSinglePixRange win=FilterPanel,disable=1
	endif
END


//***************************************

Function V9_defaultFilterValuesButton(ctrlName) : ButtonControl
	String ctrlName
	V9_defaultFilterValues()
END

Function V9_defaultFilterValues()
	String ctrlName
	if (DataFolderExists(":GraphParameters"))
		wave/z VelRange=:GraphParameters:W_VelRange
		wave/z AngleRange=:GraphParameters:W_AngleRange
//		wave/z ThetaRange=:V3_GraphParameters:W_ThetaRange
		wave/z IntRange=:GraphParameters:W_IntRange

		NVAR G_checkAngleMAX=:GraphParameters:G_checkAngleMAX
		NVAR G_checkAngleMIN=:GraphParameters:G_checkAngleMIN
		V9_switchANGLErange()	
		VelRange={0,3}
		AngleRange={G_checkAngleMIN,G_checkAngleMAX}
//		ThetaRange={0,360}
		IntRange={0,255}
	endif
END

Function V9_refreshCheckFiltering()		//030528
	NVAR/z  G_checkVel=:GraphParameters:G_checkVel
	NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
	NVAR/z G_checkInt=:GraphParameters:G_checkInt	
	NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
	NVAR/z G_checkImgMask=:GraphParameters:G_checkImgMask
	NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove
	NVAR/z G_checkFiltering=:GraphParameters:G_checkFiltering

	G_checkFiltering=G_checkVel+G_checkangle+G_checkInt+G_checkRoi+G_checkImgMask+G_checkSinglePixRemove
END

Function V_turnOFFallFilter()			//030729
		NVAR/z  G_checkVel=:GraphParameters:G_checkVel
		NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
		NVAR/z G_checkInt=:GraphParameters:G_checkInt	
		NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
		NVAR/z G_checkImgMask=:GraphParameters:G_checkImgMask
		NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove
		G_checkVel=0
		G_checkAngle=0		
		G_checkInt=0
		G_checkRoi=0
		G_checkImgMask=0
		G_checkSinglePixRemove=0
		RemoveFilteredWaveTrace()
END


//************* FIltering MAIN*******************************************************
Function V9_DoFilterValuesButton(ctrlName) : ButtonControl
	String ctrlName
//	NVAR G_check2Dstat=:GraphParameters:G_check2Dstat
	//SettingDataFolder(WaveRefIndexed("",0,1))
	SetToTopImageDataFolder()
	V9_refreshCheckFiltering()	
	V9_DoFilterValues()
	V_updateRangeDrawing()
	NVAR G_checkPrintHist=:GraphParameters:G_checkPrintHist
	if (G_checkPrintHist)
		V_printResults()
	endif
	V_CheckRoughDir() //030813
	if (V_CheckForceHistPresence()==1)		//030813
		V_FlowHist()
	endif

END

Function V9_DoFilterValues()
	wave filter=$(":GraphParameters:"+V9_returnFiltername(0))
	NVAR/z  G_checkVel=:GraphParameters:G_checkVel
	NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
	NVAR/z G_checkInt=:GraphParameters:G_checkInt				
	NVAR G_check2Dstat=:GraphParameters:G_check2Dstat		
	NVAR G_checkFilterVecDisplay=:GraphParameters:G_checkFilterVecDisplay		
	NVAR G_checkFiltering=:GraphParameters:G_checkFiltering
//	NVAR/z G_checkFlowSubtraction=:V3_GraphParameters:G_checkFlowSubtraction

	//SettingDataFolder(WaveRefIndexed("",0,1))
//	if (G_checkFlowSubtraction==0)
		V9_clearFilter2D()
		RemoveFilteredWaveTrace()
		NVAR isPosition
		//HistAnalCore(1,isPosition,0) 030805 // is NOT filtered 
		V_VelAngleCalc(0)	
		if (G_check2Dstat)
			if ((G_checkVel==1) && (G_checkAngle==1))
				V9_DoVeloAngl2DHist()
			endif
			if ((G_checkInt==1) && (G_checkAngle==1))
				V9_DoIntAngl2DHist()
			endif
			if ((G_checkVel==1) && (G_checkInt==1))
				V9_DoVeloInt2DHist()
			endif
		endif
		If (G_checkFiltering>0)
			SettingDataFolder(WaveRefIndexed("",0,1))
			V9_FiltPanelFiltering()
			Vec_V2DFilter_v2(filter)
			if (G_checkFilterVecDisplay==1)			// display filtered vectorfield part
				V9_2Dhistanal_visualization()		
			endif
		endif

//	else		// follwoing will be the Flow Subtraction
//		print "Flow Subtraction"
//		V3_FlowSub()
//	endif	
END

// function for modifying the filter3D
// 030527 could be further add the ROI filterig  and simplify the ROI special routins
// 030725 copied to VEC9 program
// 030727 above ROI fnction added
Function V9_FiltPanelFiltering()		//030525
	wave/z VelRange=:GraphParameters:W_VelRange
	wave/z AngleRange=:GraphParameters:W_AngleRange
//	wave/z ThetaRange=:V9_GraphParameters:W_ThetaRange
	wave/z IntRange=:GraphParameters:W_IntRange
	NVAR/z  G_checkVel=:GraphParameters:G_checkVel
	NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
//	NVAR/z G_checkTheta=:GraphParameters:G_checkTheta
	NVAR/z G_checkInt=:GraphParameters:G_checkInt	
	NVAR/z G_checkRoi=:GraphParameters:G_checkRoi
	NVAR/z G_checkImgMask=:GraphParameters:G_checkImgMask
	NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove

	//V3_clearFilter3D()			//deleted 030527
	if (G_checkAngle==1)
		V9_switchANGLErange()
		V9_setFilterLM(1,AngleRange[0],AngleRange[1])
	endif

	if (G_checkVel==1)
		V9_setFilterLM(2,VelRange[0],VelRange[1])
	endif

	if (G_checkInt==1)
		V9_setFilterLM(3,IntRange[0],IntRange[1])
	endif
	
	if (G_checkRoi==1)
		V9_applyROIfilter()
	endif
	
	if (G_checkImgMask==1)
		 V_applyImgMask()
	endif

	if (G_checkSinglePixRemove==1)
		 V_applySinglePixRemovefilter()
	endif	
	
END

// ************  Filter Panel *******************************************************

Function V9_CreateFilterPanel()
	String FolderList=V9_ListAllFolderNames()

	String WindowMatching=Winlist("FilterPanel",";","")
	if (WhichListItem("FilterPanel", WindowMatching)!=(-1))
		DoWindow/F  FilterPanel
		
	else
		NewPanel /W=(450,10,750,260)		//300 x 250
		DrawText 120,13,"Filter Panel "
		DoWindow/C/T FilterPanel,"Filter Panel"
		PopupMenu FolderListPop proc=V9_FilterPanelFLPopMenuProc,title="Folder";DelayUpdate
//		PopupMenu FolderListPop value=V9_ListAllFolderNames()
		PopupMenu FolderListPop value=V_listALLVecWindow()
		PopupMenu FolderListPop pos={5,30}
	endif
END


Function V9_FilterPanelFLPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	DoWindow/f $popstr
	DoWindow/f FilterPanel
	String TargetFolder=V_rtnFolderNameFromVecWIn(popStr)
	Setdatafolder ("root:"+TargetFolder)
	 InitGraphParameters()
	wave/z VelRange=:GraphParameters:W_VelRange
	wave/z AngleRange=:GraphParameters:W_AngleRange
//	wave/z ThetaRange=:GraphParameters:W_ThetaRange
	wave/z IntRange=:GraphParameters:W_IntRange
	NVAR G_checkAngleMAX=:GraphParameters:G_checkAngleMAX
	NVAR G_checkAngleMIN=:GraphParameters:G_checkAngleMIN
	 V9_switchANGLErange()

	 
	SetVariable setvarVEL_min pos={15,60},size={130,20},title="Velocity Min",value=:GraphParameters:W_VelRange[0]
	SetVariable setvarVEL_min limits={0,10,0.01}
	SetVariable setvarVEL_max pos={150,60},size={100,20},title="Max",value=:GraphParameters:W_VelRange[1]
	SetVariable setvarVEL_max limits={0,10,0.01}

	SetVariable setvarAngle_min pos={15,85},size={130,20},title="Angle   Min",value=:GraphParameters:W_AngleRange[0]
	SetVariable setvarAngle_min limits={G_checkAngleMIN,G_checkAngleMAX,5}
	SetVariable setvarAngle_max pos={150,85},size={100,20},title="Max",value=:GraphParameters:W_AngleRange[1]
	SetVariable setvarAngle_max limits={G_checkAngleMIN,G_checkAngleMAX,5}
	
	CheckBox FP_checkAngleNOT  pos={20,105},title=" NOT include this range",variable=:GraphParameters:G_checkAngleNOT
	
//	SetVariable setvarTheta_min pos={15,110},size={130,20},title="Theta Min",value=:V3_GraphParameters:W_ThetaRange[0]
//	SetVariable setvarTheta_min limits={0,360,5}
//	SetVariable setvarTheta_max pos={150,110},size={100,20},title="Max",value=:V3_GraphParameters:W_ThetaRange[1]
//	SetVariable setvarTheta_max limits={0,360,5}

	SetVariable setvarInt_min pos={15,135},size={130,20},title="Intensity Min",value=:GraphParameters:W_IntRange[0]
	SetVariable setvarInt_min limits={0,65536,5}
	SetVariable setvarInt_max pos={150,135},size={100,20},title="Max",value=:GraphParameters:W_IntRange[1]
	SetVariable setvarInt_max limits={0,65536,5}

	CheckBox FP_checkVel  pos={260,60},title="",variable=:GraphParameters:G_checkVel
	CheckBox FP_checkAngle  pos={260,85},title="",variable=:GraphParameters:G_checkAngle
//	CheckBox FP_checkTheta  pos={260,110},title="",variable=:V3_GraphParameters:G_checkTheta
	CheckBox FP_checkInt  pos={260,135},title="",variable=:GraphParameters:G_checkInt

	
	//CheckBox FP_checkRoi  disable=2, pos={15,160},title="ROI",variable=:GraphParameters:G_checkRoi	
	CheckBox FP_checkRoi pos={15,160},title="ROI",variable=:GraphParameters:G_checkRoi	
	CheckBox FP_check2Dstat  pos={60,160},title="2Dstat",variable=:GraphParameters:G_check2Dstat
	SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName 
	string ImgMaskTitle="Mask: "+S_ImgMaskName
	CheckBox FP_checkImageMask  pos={115,160},title=ImgMaskTitle,variable=:GraphParameters:G_checkImgMask, proc=V9_checkMaskImg
	CheckBox FP_checkSinglePixIgnore  pos={15,180},title="Ignore 1pix Signal",variable=:GraphParameters:G_checkSinglePixRemove, proc=V9_checkSinglePixRemove
	SetVariable setSinglePixRange pos={125,180},size={100,20},title="Int Range%",value=:GraphParameters:G_ContinuumRange
	NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove
	variable CheckSPR=((G_checkSinglePixRemove==1) ? 0 : 1)
	SetVariable setSinglePixRange limits={0,50,1},disable=CheckSPR
		
	CheckBox FP_checkFilterVecDisplay  pos={15,200},title="Display Filtered",variable=:GraphParameters:G_checkFilterVecDisplay
	CheckBox FP_checkPrintHist pos={115,200},title="Print Results",variable=:GraphParameters:G_checkPrintHist	

//	CheckBox FP_checkFlowSubtraction  pos={115,160},title="Flow Subtraction",variable=:V3_GraphParameters:G_checkFlowSubtraction

	Button DefaultFilterVal  pos={190,230},size={40,20},proc=V9_defaultFilterValuesButton;DelayUpdate
	Button DefaultFilterVal title="default"		
	Button DoFilterVal  pos={240,230},size={40,20},proc=V9_DoFilterValuesButton;DelayUpdate
	Button DoFilterVal title="Do It!"

	Button UpdateRangeDraw  pos={120,230},size={60,20},proc=V9_updateRangeDrawButton;DelayUpdate
	Button UpdateRangeDraw title="Update FR"		
	//SetVariable setvarVEL_min proc=V3_SetVarMinProc
	controlUpdate/A
	
End	

///*******************************************************************************************************


//030528 implement the combination of Flow subtraction and Filtering
//Function V3_DoFilterValues()
//	Set_CurrentPlotDataFolder()		//030605
//	NVAR/z  G_checkVel=:V3_GraphParameters:G_checkVel
//	NVAR/z G_checkPhai=:V3_GraphParameters:G_checkPhai
//	NVAR/z G_checkTheta=:V3_GraphParameters:G_checkTheta
//	NVAR/z G_checkInt=:V3_GraphParameters:G_checkInt	
//	NVAR/z G_checkRoi=:V3_GraphParameters:G_checkRoi	
//	NVAR/z G_check1Dstat=:V3_GraphParameters:G_check1Dstat		
//	NVAR/z G_checkFilterVecDisplay=:V3_GraphParameters:G_checkFilterVecDisplay		
//	NVAR/z G_checkFiltering=:V3_GraphParameters:G_checkFiltering
//	NVAR/z G_checkFlowSubtraction=:V3_GraphParameters:G_checkFlowSubtraction
//
//	
//	
//		V3_refreshCheckFiltering()
//		If ((G_checkFiltering==0) && (G_checkRoi==0) && (G_checkFlowSubtraction==0))
//			if (G_check1Dstat==0)
//				V3_DoStatAnalysis()
//			else
//				V3_DoStatAnalysis_OLD()
//			endif
//			
//			print "All vec stat"
//		else	
//			V3_clearFilter3D(); print "filter3D cleared..."
//			if (G_checkRoi==1)
//				V3_VecROI_1DV_2DAnglePanel()
//				print "ROI applied"
//			endif
//			if (G_checkFiltering>0)
//				V3_FiltPanelFiltering()
//				print "Velocity, Intensity or Angle Filter applied"
//			endif
//			//V3_VYZFiltering()			//with this line, Vfs filtering by filter3D is completed.
//			VEC3D_getFilteredVectorField()		
//
//			if (G_checkFlowSubtraction==1)
//				if ((G_checkFiltering>0) || (G_checkRoi==1))
//					print "Flow Subtraction From Filtered"
//					V3_FlowSubProcessFilter()
//				else
//					print "Flow Subtraction from Original"
//					V3_FlowSub()
//					abort
//				endif
////			else
////				wave/z VX3Df,VY3Df,VZ3Df
////				V3_averagingCore(VX3Df,VY3Df,VZ3Df)
////				Vec3D_displayPreProcess(VX3Df,VY3Df,VZ3Df)
////				V3_checkTprojeciton3Dexists()			
//			endif	
//			V3_3DtoColorWave(VZ3D1D)
//			V3_3DtoColorWave(VY3D1D)
//			V3_3DtoColorWave(VX3D1D)
//
//		endif
//
//		if (G_checkFilterVecDisplay==1)			// display filtered vectorfield part
//			V3_DrawVectorALLcoreInteg()		
//		endif		
//
//		If (((G_checkFiltering!=0) || (G_checkRoi!=0) ) && (G_checkFlowSubtraction==0))
//			if (G_check1Dstat==0)
//				V3_DoFilteredStatAnalysis()
//			else
//				V3_DoFilteredStatAnalysis1D()
//			endif
//		else
//			if  (G_checkFlowSubtraction==1)
//				V3_DoFilteredStatAnalysis_flow()	
//			endif
//		endif	
//
//END

//*******************************************************************

//V3_setFilterLM(type,minV,maxV)




////***************** Flow Subtraction***********************
//
//Function V3_FlowSubCheckProc(ctrlName,checked) : CheckBoxControl		//temporal to restrict the FlowSub processing only for the Original Vec
//	String ctrlName
//	Variable checked
//	
//	NVAR/z  G_checkVel=:V3_GraphParameters:G_checkVel
//	NVAR/z G_checkPhai=:V3_GraphParameters:G_checkPhai
//	NVAR/z G_checkTheta=:V3_GraphParameters:G_checkTheta
//	NVAR/z G_checkInt=:V3_GraphParameters:G_checkInt	
//	NVAR/z G_checkRoi=:V3_GraphParameters:G_checkRoi	
//	NVAR/z G_check1Dstat=:V3_GraphParameters:G_check1Dstat		
//	NVAR/z G_checkFilterVecDisplay=:V3_GraphParameters:G_checkFilterVecDisplay		
//	NVAR/z G_checkFiltering=:V3_GraphParameters:G_checkFiltering	
//	
//	NVAR/z G_checkFlowSubtraction=:V3_GraphParameters:G_checkFlowSubtraction
//	
//	if (G_checkFlowSubtraction==1)
//		G_checkVel=0
//		G_checkPhai=0
//		G_checkTheta=0
//		G_checkInt=0
//		G_checkRoi=0
//		G_check1Dstat=0
//		G_checkFilterVecDisplay=1
//		G_checkFiltering=1
//		
//		SetVariable setvarVEL_min disable=2
//		SetVariable setvarVEL_max disable=2
//	
//		SetVariable setvarPhai_min disable=2
//		SetVariable setvarPhai_max disable=2
//		
//		SetVariable setvarTheta_min disable=2
//		SetVariable setvarTheta_max disable=2
//	
//		SetVariable setvarInt_min disable=2
//		SetVariable setvarInt_max disable=2
//	
//		CheckBox FP_checkVel  disable=2
//		CheckBox FP_checkPhai  disable=2
//		CheckBox FP_checkTheta  disable=2
//		CheckBox FP_checkInt  disable=2
//		
//		CheckBox FP_checkRoi disable=2
//		CheckBox FP_check1Dstat  disable=2
//		CheckBox FP_checkFilterVecDisplay  disable=2
//	
//	else
//	
//		SetVariable setvarVEL_min disable=0
//		SetVariable setvarVEL_max disable=0
//	
//		SetVariable setvarPhai_min disable=0
//		SetVariable setvarPhai_max disable=0
//		
//		SetVariable setvarTheta_min disable=0
//		SetVariable setvarTheta_max disable=0
//	
//		SetVariable setvarInt_min disable=0
//		SetVariable setvarInt_max disable=0
//	
//		CheckBox FP_checkVel  disable=0
//		CheckBox FP_checkPhai  disable=0
//		CheckBox FP_checkTheta  disable=0
//		CheckBox FP_checkInt  disable=0
//		
//		CheckBox FP_checkRoi disable=0
//		CheckBox FP_check1Dstat  disable=0
//		CheckBox FP_checkFilterVecDisplay  disable=0
//		
//	endif
//	
//End
//
//
//Function V3_checkAveragingValue(calc_average)		//030528
//	variable calc_average
//	variable correct=0
//	NVAR averaging
//	if (calc_average==averaging)
//		correct=1
//	endif
//	return correct
//end
//
//Function V3_checkAveragingZValue(calc_averageZ)		//030528
//	variable calc_averageZ
//	variable correct=0
//	NVAR averagingZ
//	if (calc_averageZ==averagingZ)
//		correct=1
//	endif
//	return correct
//end
//
//Function V3_createFlowVec()	//030528
//	wave/z VX3D,VY3D,VZ3D
//	wave/z VX3Dav,VY3Dav,VZ3Dav
//	wave/z VX3Df,VY3Df,VZ3Df
//	NVAR/z averaging
//	NVAR/z averagingZ 
//	Duplicate/O VX3D VX3Dp
//	Duplicate/O VY3D VY3Dp
//	Duplicate/O VZ3D VZ3Dp
//	VX3Dp[][][]=VX3Dav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
//	VY3Dp[][][]=VY3Dav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
//	VZ3Dp[][][]=VZ3Dav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
//	VX3Df=VX3D-VX3Dp
//	VY3Df=VY3D-VY3Dp
//	VZ3Df=VZ3D-VZ3Dp
//end
//
//// following is to create Flow from Vav and subtract
//// Do this only after the Vf is already filtered.
//Function V3_createFlowVecFromFiltered()	//030528
//	wave/z VX3D,VY3D,VZ3D
//	wave/z VX3Dfav,VY3Dfav,VZ3Dfav
//	wave/z VX3Df,VY3Df,VZ3Df
//	NVAR/z averaging
//	NVAR/z averagingZ 
//	Duplicate/O VX3D VX3Dp
//	Duplicate/O VY3D VY3Dp
//	Duplicate/O VZ3D VZ3Dp
//	VX3Dp[][][]=VX3Dfav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
//	VY3Dp[][][]=VY3Dfav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
//	VZ3Dp[][][]=VZ3Dfav[trunc(p/averaging)][trunc(q/averaging)][trunc(r/averagingZ)]
////	VX3Df=VX3Df-VX3Dp
////	VY3Df=VY3Df-VY3Dp
////	VZ3Df=VZ3Df-VZ3Dp
//	VX3Df[][][]-=VX3Dp[p][q][r]
//	VY3Df[][][]-=VY3Dp[p][q][r]
//	VZ3Df[][][]-=VZ3Dp[p][q][r]
//
//end
//
//
//Function V3_FlowSub()		//030528
//
//	wave/z VX3D,VY3D,VZ3D
//	wave/z VX3Dav,VY3Dav,VZ3Dav
//	wave/z VX3Df,VY3Df,VZ3Df
//	if (waveexists(VXf)==0)
//		V3_createVf()		//main.ipf
//	endif
////	variable calc_average=trunc(DimSize(VX3D,0)/DimSize(VX3Dav,0))
////	if ((V3_checkAveragingValue(calc_average)==0) && (V3_checkAveragingZValue(calc_average)==0))
////		abort "Do the averaging again. \rStored averaging value is different from the current average Vec Field."
////	else
//		//NVAR/z G_checkFiltering=:V3_GraphParameters:G_checkFiltering
//		//printf "Filter Check Flow Sub %g\r",G_checkFiltering
//		V3_createFlowVec()
//		V3_averagingCore(VX3Df,VY3Df,VZ3Df)
//		Vec3D_displayPreProcess(VX3Df,VY3Df,VZ3Df)
//		V3_checkTprojeciton3Dexists()
//		
//		V3_DrawVectorALLcoreInteg()	
////	endif
//END
//
//Function V3_FlowSubProcessFilter()		//030528
//
//	wave/z VX3D,VY3D,VZ3D
//	//wave/z VX3Dav,VY3Dav,VZ3Dav
//	wave/z VX3Df,VY3Df,VZ3Df
//	if (waveexists(VXf)==0)
//		V3_createVf()		//main.ipf
//	endif
//		V3_createFlowVecFromFiltered()
//		V3_averagingCore(VX3Df,VY3Df,VZ3Df)
//		Vec3D_displayPreProcess(VX3Df,VY3Df,VZ3Df)
////		V3_checkTprojeciton3Dexists()
////		
////		V3_DrawVectorALLcoreInteg()	
////	endif
//END
//
//////////////////////////////////////////----- Flow Sub Stats---------------////////////////////////////////////////////////////////
//
//Function V3_stat_FilteredVelocity()		//030528
////	String CurrentPlot=Set_CurrentPlotDataFolder()
//	wave/z VX3Df,VY3Df,VZ3Df
// 	wave/z Vec_velF
//	Vec_velF[][][]=((VX3Df[p][q][r])^2 + (VY3Df[p][q][r])^2 + (VZ3Df[p][q][r])^2 )^0.5
//	V3_stat_VelocityHist(Vec_velF)
////	setdatafolder root:
//END	
//
//
//Function V3_stat_theta_absoluteFiltCore()			//030528
//	wave/z VX3Df,VY3Df,VZ3Df//,Vec_vel
//	wave/z Vec_radF,Vec_degF
//
//	Vec_radF[][][]=V3_VecTheta3D(VX3Df[p][q][r],VY3Df[p][q][r]) //020908 
//	Vec_radF[][][]=( (VX3Df[p][q][r] >0) ? (2*pi-Vec_radF[p][q][r]) : Vec_radF[p][q][r]) 
//	Vec_degF[][][]=((Vec_radF[p][q][r]!=Nan) ? (Vec_radF[p][q][r]/2/3.1415*360): (Nan))
//END
//
//Function V3_stat_Phai_absoluteFiltCore()				//030528
//	wave/z VX3Df,VY3Df,VZ3Df//,Vec_vel
//	wave/z Vec_radPhaiF,Vec_degPhaiF
//	Vec_radPhaiF[][][]=V3_VecPhai3D(VX3Df[p][q][r],VY3Df[p][q][r],VZ3Df[p][q][r])
//	Vec_radPhaiF[][][]=( (VZ3Df[p][q][r] <0) ? (-1*Vec_radPhaiF[p][q][r]) : Vec_radPhaiF[p][q][r]) 
//	Vec_degPhaiF[][][]=((Vec_radPhaiF[p][q][r]!=Nan) ? (Vec_radPhaiF[p][q][r]/2/3.1415*360): (Nan))
//END
//
//
//Function V3_stat_Angle_absoluteFilt()			// 030528
//	//String CurrentPlot=Set_CurrentPlotDataFolder()
//	
//	V3_stat_theta_absoluteFiltCore()
//	V3_stat_Phai_absoluteFiltCore()
//	
//	wave/z	Vec_radF,Vec_degF,Vec_radPhaiF,Vec_degPhaiF
//	V3_cmprANDset03Dx2(Vec_radF,Vec_radPhaiF)
//	V3_cmprANDset03Dx2(Vec_degF,Vec_degPhaiF)
//
//	V3_stat_radHist(Vec_radF)
//	V3_stat_degHist(Vec_degF)	
//
//	V3_stat_radPhaiHist(Vec_radPhaiF)	
//	V3_stat_degPhaiHist(Vec_degPhaiF)	
//
//END
//
////--- - - - - - --- - Graphing 
//
//Function V3_DoFilteredStatAnalysis_flow()			//0330528
//	//String CurrentPlot=Set_CurrentPlotDataFolder()
//	//Printf "Current Data Folder= %s\r", CurrentPlot
//
//		String presentWindows
//		presentWindows=WinList((V3_VectorFieldWindowName()+"*"), ";", "" )		
//		V3_stat_FilteredVelocity()	//030528 V3_stat_VelocityFiltered() //V3_stat_Velocity()
////		V3_stat_Theta_absoluteFiltered()
////		V3_stat_Phai_absoluteFiltered()
//		V3_stat_Angle_absoluteFilt()			// 030528	
//		wave/z Vec_velF,Vec_velFH,Vec_radF,Vec_radFH,Vec_radPhaiF,Vec_radPhaiH,AnglePlot2DF
//		
//		//if (WhichListItem(V3_HistWinName(3), presentWindows)==(-1))		//mag
//		if (WhichListItem(V3_HistWinName(0), presentWindows)==(-1))		//mag
//			V3SpeedHistShow(Vec_velH,0)
//			V3_appendFilteredSpeed(Vec_velFH,V3_HistWinName(0))
//			//V3SpeedHistShow(Vec_velFH,1)
//			V3TextBox_Hist_Vec(Vec_Vel,V3_HistWinName(0))
//			V3TextBox_Hist_VecFiltered(Vec_VelF,V3_HistWinName(0))
//		else
//			//DoWindow/F $V3_HistWinName(3)
//			DoWindow/F $V3_HistWinName(0)
//			string PresentTraces=TracenameList("", ";", 1)
//			//print PresentTraces
//			if (WhichListItem(Nameofwave(Vec_velFH), PresentTraces)==(-1))
//				V3_appendFilteredSpeed(Vec_velFH,V3_HistWinName(0))
//			endif
//			V3TextBox_Hist_VecFiltered(Vec_VelF,V3_HistWinName(0))
//		endif
//						
//		if (WhichListItem(V3_HistWinName(13), presentWindows)==(-1))		//2Ddeg
//			//V3_Do2DhistoFiltered()
//			V3_Do2DhistoGEN(1)
//			//V3TextBox_Hist_Vec(Vec_deg,V3_HistWinName(2))
//		else
//			DoWindow/F $V3_HistWinName( str2num(V3_hist2Dnames(1,6)) )
//			//V3_2Dhisto(vec_radF,vec_radPhaiF,AnglePlot2DF,1)
//			wave/z wavex=$V3_hist2Dnames(1,1)
//			wave/z wavey=$V3_hist2Dnames(1,0)
//			wave/z wave2D=$V3_hist2Dnames(1,2)
//			V3_2DhistoGEN(waveX,wavey,wave2D,1)
//
//			//V3TextBox_Hist_Vec(Vec_deg,V3_HistWinName(2))
//		endif
//
//		//setdatafolder root:
//	//endif
//END




//----------------------- UNUSED ------------------


//Function V9_calculateFilter2D()		//from current folder	//integrate all filters by multiplication //030523 aovid using this for memory saving
//	wave/z filter2D=:GraphParameters:filter2D
//	variable i
//	for (i=1; i<5;i+=1)
//		wave/z specificFilter=$(":GraphParameters:"+V9_returnFiltername(i))
//		filter2D*=specificFilter
//	endfor
//END 
//
//Function V9_calculateFilter2DSP(type)		//from current folder		//030523 aovid using this for memory saving
//	variable type
//	wave/z filter2D=:GraphParameters:filter2D
//	wave/z specificFilter=$(":GraphParameters:"+V9_returnFiltername(type))
//	filter2D*=specificFilter
//END 
//
//Function V9_calculateFilterROI2D()		//from current folder //conjugate ROI and Filter
//	variable type
//	wave/z filter2D=:GraphParameters:filter2D
//	wave/z RoiFilter=:GraphParameters:ROIfilter //$(":v3_GraphParameters:"+V3_returnFiltername(type))
//	filter2D*=RoiFilter
//END 