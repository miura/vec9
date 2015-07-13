#pragma rtGlobals=1		// Use modern global access method.

//(030516)
// for simulating the "Flow" from the vector field.
//single iteration causes the movement of the corresponding intensity to the destination directed by the 
//vector field.  
//in the follwoing example, the vectorfield itself moves with the dots.

//(030521)
//there should be way to avioid "accumulation" of the signals.
// -- using the first frame tried
//-- control panel implimented

//040510
// further plan:
//	actual distance.
//	actual concentration.

Function V9_MenuIterateFlow()    // InitialStartUp 

	variable iterationBoost,iteration
	string igsave_path
	iterationBoost=3
	iteration=20
	igsave_path="pp"
	
	String saveDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	wave src3Dwave=$V9_Original3Dwave()
	NVAR LayerStart,LayerEND
//	V9_ExtractMidFrame(src3Dwave,LayerStart,LayerEND) //imageprocessing.ipf
//	String MidSliceName=V9_MidSliceName(src3Dwave)
	String MidSliceName= V9_FirstFrameName()		//0303521	trial of using the firstframe
	wave/z MidSlice=$MidSliceName
	String FlowImageName=V9_FlowImageName(src3Dwave)
	Duplicate/O $MidSliceName $FlowImageName,tempFlow
	wave FlowImage=$FlowImageName

	NVAR/z simFil=:Analysis:SimFil
	NVAR/z ItBoost=:Analysis:ItBoost
	NVAR/z IterateNo=:Analysis:IterateNo
	NVAR/z simImSave=:Analysis:simImSave
	SVAR/z PathSave=:Analysis:PathSave		
	String SimWinName=SimWindowName()
	String WindowMatching=Winlist(SimWinName,";","")
	if (WhichListItem(SimWinName, WindowMatching)!=(-1))
		DoWindow/F  $SimWinName
		ControlUpdate/A	
	else
		initializeSimFil()
		initializeItboost()
		initializeIterateNo()
		initializeSimImageSave()
		initializePathSave()				

		simFil=0	
		simImSave=0
		ItBoost=iterationBoost
		IterateNo=iteration
		PathSave=""
		DisplayFlowSimu(MidSlice,FlowImage)
		DoWindow/C  $SimWinName
		ControlUpdate/A			
	endif
	DoUpdate
	print "image shown"
	SetDataFolder saveDF		
END

Function V9_IterateFlow(iterationBoost,iteration)//,igsave_path)    // iterationBoost: shortcutting iteration by this magnitude
	variable iterationBoost,iteration
	string igsave_path
	
	String saveDF=GetDataFolder(1)
	if (SetToTopImageDataFolder()==0)
		abort "No Image In the Top Graph"
	endif

	wave src3Dwave=$V9_Original3Dwave()
	NVAR LayerStart,LayerEND
//	V9_ExtractMidFrame(src3Dwave,LayerStart,LayerEND) //imageprocessing.ipf
//	String MidSliceName=V9_MidSliceName(src3Dwave)
	String MidSliceName= V9_FirstFrameName()		//0303521	trial of using the firstframe
	wave/z MidSlice=$MidSliceName
	String FlowImageName=V9_FlowImageName(src3Dwave)
	Duplicate/O $MidSliceName $FlowImageName,tempFlow
	wave FlowImage=$FlowImageName
	

	NVAR Unit
	variable offset
	if (Unit==3)
		offset=1
	else
		offset=0
	endif
	variable IterationPerImage=DimSize(FlowImage,0)*DimSize(FlowImage,1)
	variable i,j,k
	variable StepX,StepY,NewX,NewY
	NVAR/z simFil=:Analysis:SimFil
	NVAR/z ItBoost=:Analysis:ItBoost
	NVAR/z IterateNo=:Analysis:IterateNo
	NVAR/z simImSave=:Analysis:simImSave
	SVAR/z PathSave=:Analysis:PathSave
	String SimWinName=SimWindowName()
	String WindowMatching=Winlist(SimWinName,";","")
	if (WhichListItem(SimWinName, WindowMatching)!=(-1))
		DoWindow/F  $SimWinName
		ControlUpdate/A	
	else
		initializeSimFil()
		initializeItboost()
		initializeIterateNo()
		initializeSimImageSave()
		initializePathSave()	
		simFil=0	
		simImSave=0
		ItBoost=iterationBoost
		IterateNo=iteration
		PathSave=""
		DisplayFlowSimu(MidSlice,FlowImage)
		DoWindow/C  $SimWinName
		ControlUpdate/A			
	endif
	DoUpdate
	//print "image shown"	

	if (SimFil==0)	
		wave VX,VY
		Duplicate/o VX VX_temp1,VX_temp2
		Duplicate/o VY VY_temp1,VY_temp2
	else	
		wave VX_filtered,VY_filtered
		Duplicate/o VX_filtered VX_temp1,VX_temp2
		Duplicate/o VY_filtered VY_temp1,VY_temp2
	endif
	
	for (k=0;k<iteration;k+=1)
		if (simImSave==1)
			string filename
			sprintf filename, "Simu%4g.bmp",k
			ImageSave/O/D=16/T="BMPf"/P=$PathSave FlowImage filename
		endif	
		for (i=0;i<DimSize(MidSlice,1);i+=1)
			for (j=0;j<DimSize(MidSlice,0);j+=1)
				//print "s"
				stepX=trunc((VX_temp1[j+offset][i+offset])*iterationBoost)
				stepY=trunc((VY_temp1[j+offset][i+offset])*iterationBoost)
				stepX=(numtype(stepX)!=0 ? 0 : stepX)
				stepY=(numtype(stepY)!=0 ? 0 : stepY)
				//print "StepX %g StepY %g",stepX,stepY
	
				NewX=j+stepX
				NewX=(NewX<0 ? 0 : NewX)
				NewX=( (NewX>=DimSize(FlowImage,0)) ? DimSize(FlowImage,0) : NewX)
	
				NewY=i+stepY
				NewY=(NewY<0 ? 0 : NewY)
				NewY=( (NewY>=DimSize(FlowImage,0)) ? DimSize(FlowImage,0) : NewY)
	
				if ((stepX!=0) || (stepY!=0))
					tempFlow[j][i]=tempFlow[j][i]-FlowImage[j][i]
					tempFlow[NewX][NewY]=tempFlow[NewX][NewY]+FlowImage[j][i]
					
					VX_temp2[j][i]=VX_temp2[j][i]-VX_temp1[j][i]
					VY_temp2[j][i]=VY_temp2[j][i]-VY_temp1[j][i]
					VX_temp2[NewX][NewY]=VX_temp2[NewX][NewY]+VX_temp1[j][i]
					VY_temp2[NewX][NewY]=VY_temp2[NewX][NewY]+VY_temp1[j][i]
				endif
				//printf "row %g\r", j
			endfor
			//printf "col %g\r", i
		endfor
//		printf "iteration %g\r", k
		printf "."
		FlowImage=tempflow
		VX_temp1=VX_temp2
		VY_temp1=VY_temp2
		
		ModifyImage $FlowImagename ctab= {*,255,Grays,0}
		DoUpdate

	endfor
	killwaves tempFlow,VX_temp1,VX_temp2,VY_temp1,VY_temp2
	printf "\r"
	SetDataFolder saveDF		
END

Function DisplayFlowSimu(MidSlice,FlowImage)
	wave MidSlice,FlowImage
	Display;AppendImage/L=imL1/B=im1 MidSlice
	AppendImage/L=im2L/B=im2 FlowImage
	ModifyGraph axisEnab(im1)={0,0.45},axisEnab(im2)={0.55,1}
	ModifyGraph height={Plan,1,imL1,im1}
	ModifyGraph freePos(imL1)=0,freePos(im1)=0,freePos(im2L)=0,freePos(im2)=0
	ModifyGraph margin(left)=30,margin(bottom)=80

	CheckBox filter_check proc=FilterCheckProc,title="Filtered Vec"
	CheckBox filter_check pos={14,245}
	
	CheckBox ImageSave_check proc=SimuImageSaveCheckProc,title="Save Sequence"
	CheckBox ImageSave_check pos={14,275}	

	SetVariable ItBoost size={110,20},proc=FlowSimu_SetVarProc
	SetVariable ItBoost title="Iteration Boost",limits={0,10,1},value=:Analysis:ItBoost
	SetVariable ItBoost pos={100,245}	

	SetVariable Iterate size={110,20},proc=FlowSimuIterate_SetVarProc
	SetVariable Iterate title="Iterations",limits={1,150,2},value=:Analysis:IterateNo
	SetVariable Iterate pos={250,245}

	PopupMenu popup_pathlist pos={147,275},proc=Simupathlist_PopMenuProc
	PopupMenu popup_pathlist title="Path for saving the sequence:"
	PopupMenu popup_pathlist value=PathList("*",";","")
	
	Button DoFlowSimu proc=FlowSimu_DoButtonProc,title="Do It!"
	Button DoFlowSimu pos={400,240}	

	ControlUpdate/A		
END

Function FlowSimu_DoButtonProc(ctrlName) : ButtonControl
	String ctrlName
	NVAR/z ItBoost=:Analysis:ItBoost
	NVAR/z IterateNo=:Analysis:IterateNo
	String igsave_path="pp"
	printf "ItBoost %g Iteration %g\r",ItBoost,IterateNo
	V9_IterateFlow(ItBoost,IterateNo)//,igsave_path) 
End

Function FilterCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR/z simFil=:Analysis:simFil
	if (NVAR_exists(simFil)==0)
		variable/g :Analysis:simFil
		NVAR/z simFil=:Analysis:simFil
	endif
	simFil=checked
End

Function SimuImageSaveCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR/z simImSave=:Analysis:simImSave
	if (NVAR_exists(simImSave)==0)
		variable/g :Analysis:simImSave
	NVAR/z simImSave=:Analysis:simImSave
	endif
	simImSave=checked
End

Function FlowSimu_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR/z ItBoost=:Analysis:ItBoost
//	NVAR/z K0
	ItBoost=varNum
End

Function FlowSimuIterate_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR/z IterateNo=:Analysis:IterateNo
//	NVAR/z K1
	IterateNo=varNum
End

Function Simupathlist_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR/z PathSave=:Analysis:PathSave
	if (SVAR_exists(PathSave)==0)
		String/g ::Analysis:PathSave
		SVAR/z PathSave=:Analysis:PathSave
	endif
	PathSave=popStr
End

Function initializeSimFil()
	NVAR/z simFil=:Analysis:simFil
	if (NVAR_exists(simFil)==0)
		variable/g :Analysis:simFil
		NVAR/z simFil=:Analysis:simFil
	endif
END

Function initializeSimImageSave()
	NVAR/z simImSave=:Analysis:simImSave
	if (NVAR_exists(simImSave)==0)
		variable/g :Analysis:simImSave
		NVAR/z simImSave=:Analysis:simImSave
	endif
END

Function initializeItboost()
	NVAR/z ItBoost=:Analysis:ItBoost
	if (NVAR_exists(ItBoost)==0)
		variable/g :Analysis:ItBoost
		NVAR/z ItBoost=:Analysis:ItBoost
	endif
END

Function initializeIterateNo()
	NVAR/z IterateNo=:Analysis:IterateNo
	if (NVAR_exists(IterateNo)==0)
		variable/g :Analysis:IterateNo
		NVAR/z IterateNo=:Analysis:IterateNo
	endif
END

Function initializePathSave()
	SVAR/z PathSave=:Analysis:PathSave
	if (SVAR_exists(PathSave)==0)
		String/g :Analysis:PathSave
		SVAR/z PathSave=:Analysis:PathSave
	endif
END