#pragma rtGlobals=1		// Use modern global access method.

// added 3-direction statistics 030123
// added Vec9_pairedsample_t_tests(srcwave1,srcwave2)

#include "Vec9_DatafolderIO"


Menu "Directionality"
	"Directionality analysis panel..", Panel_Histanal()
	"Show graph",DisplayHistDiranalysis()
	"-"
	"Show Approximate Direction" ,VEC9_TriDirection_Histo()		//030123
	"Do it for all opened Vec Win",DoSimpleDirection()	//040121
	"-"
	"student T test AWAY-NORMAL",Vec9_Ttest_cust(1)
	"student T test AWAY-TOWARDS",Vec9_Ttest_cust(2)
	"student T test NORMAL - TOWARDS",Vec9_Ttest_cust(3)
	"Do three waves at once_ compare2",Vec9_Ttest_custDo3Comp2(0)	
	"-"
	"student T test H3 AWAY-NORMAL",Vec9_Ttest_custV2(1)		//040113
	"student T test H3 AWAY-TOWARDS",Vec9_Ttest_custV2(2)
	"student T test H3 NORMAL - TOWARDS",Vec9_Ttest_custV2(3)
	"Do three waves at once_ compare2",Vec9_Ttest_custDo3Comp2(1)	
	"-"
	"Multiple VecField Filter",MultipleVectorField_Filtered()
	"Multiple Filter velocity & int",Multiple_Filtering()
	"Multiple filter Velocity",Multiple_Filtering_vel()	
	"Collect All FlowRate Hists",V9_CollectFlowrateAllVecWin()
	"-"
	 "Collect All Rough direction Hists",V9_Collect3DirectionAllVecWin() 	//040126
END

Function VEC9_TriDirection_Histo()			//030123		to show Towards, lateral and Away.
	String curDF=GetDataFolder(1)
//	if (DataFolderExists(":VectorFunctions")==0)
//		VectorFieldPanelInit()	
//	endif
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	NVAR isPosition
	//NVAR ispositionL=root:VectorFunctions:G_relative
	if (isPosition==0)
		Abort "The vector field must be measured relative to a reference point before doing this"
//		ispositionL=1
//		NVAR isPosition//=root:VectorFunctions:G_relative
//		isPosition=ispositionL
		//HistAnalCore(1,ispositionL,0)		
	endif
	wave/z GradWave=$(StatnameProc("deg"))	
	String Grad3HistWaveName=StatHISTnameProc("deg3")

	Make/O/N=6 tempHist
	wave/z tempHist
	Make/O/N=3 $Grad3HistWaveName
	wave/z Grad3HistWave=$Grad3HistWaveName
	Histogram/B={-180,60,6} GradWave,tempHist
	Grad3HistWave[0]=tempHist[0]+tempHist[5]
	Grad3HistWave[1]=tempHist[1]+tempHist[4]
	Grad3HistWave[2]=tempHist[2]+tempHist[3]
	NormalizeHistogram(GradWave,Grad3HistWave)
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )

	if (WhichListItem(HistWinName(11), presentWindows)==(-1))
		Make/O/T DirectionTxt
		wave/t/z DirectionTxt
		DirectionTxt={"Away","Normal","Towards"}
		TriHistGradHistShow(GradWave,Grad3HistWave,DirectionTxt)
	else
		DoWindow/F $HistWinName(11)
		TextBox_Hist_AllVecInfo(GradWave,HistWinName(11),2)
	endif
	KillWaves tempHist		
	SetDataFolder curDF	
END

//030818 added: integrate intensity in each of the thre directions
Function VEC9_TriDirectionForce_Histo()			//030123		to show Towards, lateral and Away.
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	NVAR isPosition
	//NVAR ispositionL=root:VectorFunctions:G_relative
	if (isPosition==0)
		Abort "The vector field must be measured relative to a reference point before doing this"
	endif
	wave/z w_flw=$StatnameProc("flw")
	if (waveexists(w_flw)==0)
		Abort "Force Calculation must be done before this operation"
	endif	
	wave/z GradWave=$(StatnameProc("deg"))
	wave/z FiltImgWave=$(V_PrepTempIntensityFiltered())	
	//String Grad3HistWaveName=StatHISTnameProc("deg3")

	Make/O/N=6 tempHist,temp_IntSigma,temp_Npnts
	wave/z tempHist,temp_IntSigma,temp_Npnts
	//Make/O/N=3 $Grad3HistWaveName
	Make/O/N=3 $(StatnameProc("flw")+"dirH3")
	Make/O/N=3 $(StatnameProc("flw")+"intH3")	
	Make/O/N=3 $(StatnameProc("flw")+"nptH3")
	Make/O/N=3 $(StatnameProc("flw")+"flowH3")			
	wave/z Grad3HistWave=$(StatnameProc("flw")+"dirH3")
	wave/z Int3HistWave=$(StatnameProc("flw")+"intH3")
	wave/z Npt3HistWave=$(StatnameProc("flw")+"nptH3")
	wave/z Flow3HistWave=$(StatnameProc("flw")+"flowH3")		
	tempHist=0
	temp_IntSigma=0
	temp_Npnts=0
	Grad3HistWave=0
	Int3HistWave=0
	Npt3HistWave=0
	Flow3HistWave=0
	SetScale/P x -150,60,"", tempHist
	SetScale/P x -150,60,"", temp_IntSigma		//030818
	SetScale/P x -150,60,"", temp_Npnts		//030818
	
	SetScale/P x -150,120,"", Grad3HistWave
	SetScale/P x -150,120,"", Flow3HistWave
	variable i,j,Hwidth,Hheight
	Hwidth=DimSize(GradWave,0)
	Hheight=DimSize(GradWave,1)
	for (j=0;j<Hheight;j+=1)
		for (i=0;i<Hwidth;i+=1)
			if (numtype(GradWave[i][j])==0)
				tempHist[x2pnt(tempHist,GradWave[i][j])]+=w_flw[i][j]
				temp_IntSigma[x2pnt(temp_IntSigma,GradWave[i][j])]+=FiltImgWave[i][j]
				temp_Npnts[x2pnt(temp_Npnts,GradWave[i][j])]+=1
			endif
		endfor
	endfor
	
	Grad3HistWave[0]=tempHist[0]+tempHist[5]
	Grad3HistWave[1]=tempHist[1]+tempHist[4]
	Grad3HistWave[2]=tempHist[2]+tempHist[3]
	
	Int3HistWave[0]=temp_IntSigma[0]+temp_IntSigma[5]
	Int3HistWave[1]=temp_IntSigma[1]+temp_IntSigma[4]
	Int3HistWave[2]=temp_IntSigma[2]+temp_IntSigma[3]

	Npt3HistWave[0]=temp_Npnts[0]+temp_Npnts[5]
	Npt3HistWave[1]=temp_Npnts[1]+temp_Npnts[4]
	Npt3HistWave[2]=temp_Npnts[2]+temp_Npnts[3]
	
	Flow3HistWave=Grad3HistWave/Int3HistWave
	
	//NormalizeHistogram(GradWave,Grad3HistWave)
		//NVAR G_AwayRatio
		NVAR G_AwayForce=:analysis:G_AwayForce
		NVAR G_AwayForceRatio=:analysis:G_AwayForceRatio
		NVAR G_AwayFlow=:analysis:G_AwayFlow
		NVAR G_AwayFlowRatio=:analysis:G_AwayFlowRatio		
		//NVAR G_NormalRatio
		NVAR G_NormalForce=:analysis:G_NormalForce
		NVAR G_NormalForceRatio=:analysis:G_NormalForceRatio
		NVAR G_NormalFlow=:analysis:G_NormalFlow
		NVAR G_NormalFlowRatio=:analysis:G_NormalflowRatio		
		//NVAR G_TowardsRatio
		NVAR G_TowardsForce=:analysis:G_TowardsForce
		NVAR G_TowardsForceRatio=:analysis:G_TowardsForceRatio
		NVAR G_TowardsFlow=:analysis:G_TowardsFlow
		NVAR G_TowardsFlowRatio=:analysis:G_TowardsFlowRatio		

	G_AwayForce=Grad3HistWave[0]
	G_NormalForce=Grad3HistWave[1]
	G_TowardsForce=Grad3HistWave[2]
	
	G_AwayFlow=Flow3HistWave[0]
	G_NormalFlow=Flow3HistWave[1]
	G_TowardsFlow=Flow3HistWave[2]

	Make/O/N=3 $(StatnameProc("flw")+"FRH3") // flow rate		//040111		
	Make/O/N=3 $(StatnameProc("flw")+"PVH3") // protein velocity		//040111			
	wave/z FR3HistWave=$(StatnameProc("flw")+"FRH3")		//040111
	wave/z PV3HistWave=$(StatnameProc("flw")+"PVH3")		//040111		
	
	FR3HistWave[]=Grad3HistWave		//040111
	PV3HistWave[]=Flow3HistWave		//040111
	 	
	NormalizeHistogramNoStat(Grad3HistWave)
	NormalizeHistogramNoStat(Flow3HistWave)

	G_AwayForceRatio=Grad3HistWave[0]
	G_NormalForceRatio=Grad3HistWave[1]
	G_TowardsForceRatio=Grad3HistWave[2]	

	G_AwayFlowRatio=Flow3HistWave[0]
	G_NormalFlowRatio=Flow3HistWave[1]
	G_TowardsFlowRatio=Flow3HistWave[2]
		
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(14), presentWindows)==(-1))
		Make/O/T DirectionTxt
		wave/t/z DirectionTxt
		DirectionTxt={"Away","Normal","Towards"}
		Display /W=(250,320,500,570) Grad3HistWave vs DirectionTxt
		ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
		ModifyGraph lblLatPos(left)=7
		Label left "\\Z08Flow Rate [proteins/sec] Ave. Speed [pixels/sec]"
		Label bottom "Direction"
		//ModifyGraph zero(bottom)=1
		ModifyGraph margin(bottom)=100
		ModifyGraph lblMargin(left)=7,lblMargin(bottom)=66
		ModifyGraph lblLatPos(left)=7
		SetAxis/A/E=1/N=1 left
		ModifyGraph fSize(bottom)=8
		
		AppendToGraph Flow3HistWave vs DirectionTxt
		ModifyGraph rgb($(nameofwave(Flow3HistWave)))=(16384,16384,65280)
//		Legend/C/N=text0/J/A=MC "\\Z07\\s("+nameofwave(Grad3HistWave)+") Flow [Intensity · Velocity]\r\\s("+nameofwave(Flow3HistWave)+") Flow Rate"	
		Legend/C/N=text0/J/A=MC "\\Z07\\s("+nameofwave(Grad3HistWave)+") Flow Rate\r\\s("+nameofwave(Flow3HistWave)+") Protein Movement Speed"	
		DoWindow/C $HistWinName(14)
		TextBox_ForceRoughHist_Info()		
	else
		DoWindow/F $HistWinName(14)
		TextBox_ForceRoughHist_Info()
		//TextBox_Hist_AllVecInfo(GradWave,HistWinName(14),2)
	endif
	KillWaves tempHist
	Killwaves FiltImgWave,temp_IntSigma,temp_Npnts		
	SetDataFolder curDF	
END

//060511 to show in bidrectional: modified three direction version above
Function VEC9_BiDirectionForce_Histo()			
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	NVAR isPosition
	if (isPosition==0)
		Abort "The vector field must be measured relative to a reference point before doing this"
	endif
	wave/z w_flw=$StatnameProc("flw")

	if (waveexists(w_flw)==0)
		Abort "Force Calculation must be done before this operation"
	endif

	wave/z GradWave=$(StatnameProc("deg"))
	wave/z FiltImgWave=$(V_PrepTempIntensityFiltered())	

	duplicate/O w_flw $StatnameProc("flw2")					//060511 for sin(deg) * flow. 
	wave/z w_flw2=$StatnameProc("flw2")						//060511 
	w_flw2[][]=w_flw[p][q]*	cos(GradWave[p][q]/360*2*pi)		//060511 calculate the flow along axis towards the reference point
			// in above, 
//	Make/O/N=6 tempHist,temp_IntSigma,temp_Npnts
	Make/O/N=3 tempHist,temp_IntSigma,temp_Npnts

	wave/z tempHist,temp_IntSigma,temp_Npnts
	//Make/O/N=3 $Grad3HistWaveName
	Make/O/N=3 $(StatnameProc("flw")+"dirH2")
	Make/O/N=3 $(StatnameProc("flw")+"intH2")	
	Make/O/N=3 $(StatnameProc("flw")+"nptH2")
	Make/O/N=3 $(StatnameProc("flw")+"flowH2")			
	wave/z Grad2HistWave=$(StatnameProc("flw")+"dirH2")
	wave/z Int2HistWave=$(StatnameProc("flw")+"intH2")
	wave/z Npt2HistWave=$(StatnameProc("flw")+"nptH2")
	wave/z Flow2HistWave=$(StatnameProc("flw")+"flowH2")		
	tempHist=0
	temp_IntSigma=0
	temp_Npnts=0
	Grad2HistWave=0
	Int2HistWave=0
	Npt2HistWave=0
	Flow2HistWave=0

	variable i,j,Hwidth,Hheight
	Hwidth=DimSize(GradWave,0)
	Hheight=DimSize(GradWave,1)
	for (j=0;j<Hheight;j+=1)
		for (i=0;i<Hwidth;i+=1)
			if (numtype(GradWave[i][j])==0)
				if (w_flw2[i][j]>0)	//towards
					Grad2HistWave[1]+=w_flw2[i][j]
					Int2HistWave[1]+=FiltImgWave[i][j]
					Npt2HistWave[1]+=1
				endif
				if (w_flw2[i][j]<0)	//away			
					Grad2HistWave[0]+=abs(w_flw2[i][j])
					Int2HistWave[0]+=FiltImgWave[i][j]
					Npt2HistWave[0]+=1
				endif
				if (w_flw2[i][j]==0) //stopped
					Grad2HistWave[2]+=FiltImgWave[i][j]
					Int2HistWave[2]+=FiltImgWave[i][j]
					Npt2HistWave[2]+=1
				
				endif
			endif
		endfor
	endfor
	

	Flow2HistWave=Grad2HistWave/Int2HistWave

		// might half to change the following 060511
		NVAR G_AwayForce=:analysis:G_AwayForce
		NVAR G_AwayForceRatio=:analysis:G_AwayForceRatio
		NVAR G_AwayFlow=:analysis:G_AwayFlow
		NVAR G_AwayFlowRatio=:analysis:G_AwayFlowRatio		

		NVAR G_TowardsForce=:analysis:G_TowardsForce
		NVAR G_TowardsForceRatio=:analysis:G_TowardsForceRatio
		NVAR G_TowardsFlow=:analysis:G_TowardsFlow
		NVAR G_TowardsFlowRatio=:analysis:G_TowardsFlowRatio		

	G_AwayForce=Grad2HistWave[0]
	G_TowardsForce=Grad2HistWave[1]
	
	G_AwayFlow=Flow2HistWave[0]
	G_TowardsFlow=Flow2HistWave[1]

	Make/O/N=3 $(StatnameProc("flw")+"FRH2") // flow rate		//040111	//060511	
	Make/O/N=3 $(StatnameProc("flw")+"PVH2") // protein velocity		//040111		//060511		
	wave/z FR2HistWave=$(StatnameProc("flw")+"FRH2")		//040111	//060511
	wave/z PV2HistWave=$(StatnameProc("flw")+"PVH2")		//040111		//060511	

	Make/O/N=3 Hist2_dummy
	Hist2_dummy=0
		
	FR2HistWave[]=Grad2HistWave		//040111
	PV2HistWave[]=Flow2HistWave		//040111
	 	
	NormalizeHistogramNoStat(Grad2HistWave)
	NormalizeHistogramNoStat(Flow2HistWave)

	G_AwayForceRatio=Grad2HistWave[0]
	G_TowardsForceRatio=Grad2HistWave[1]	

	G_AwayFlowRatio=Flow2HistWave[0]
	G_TowardsFlowRatio=Flow2HistWave[1]
		
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(15), presentWindows)==(-1))
		Make/O/T BiDirectionTxt
		wave/t/z BiDirectionTxt
		BiDirectionTxt={"Away","Towards","Still"}
		Display /W=(250,320,500,570) Grad2HistWave vs BiDirectionTxt
		ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
		ModifyGraph lblLatPos(left)=7
		Label left "\\Z08Flow Rate ratio [normalized: proteins/sec]"
		Label bottom "Direction"
		//ModifyGraph zero(bottom)=1
		ModifyGraph margin(bottom)=100
		ModifyGraph lblMargin(left)=7,lblMargin(bottom)=66
		ModifyGraph lblLatPos(left)=7
		SetAxis/A/E=1/N=1 left
		ModifyGraph fSize(bottom)=8
		AppendToGraph Hist2_dummy
		
		AppendToGraph/R Hist2_dummy
		AppendToGraph/R PV2HistWave vs BiDirectionTxt
		Label right "\\Z08Ave. Speed [pixels/sec]"
		ModifyGraph rgb($(nameofwave(PV2HistWave)))=(16384,16384,65280)
//		Legend/C/N=text0/J/A=MC "\\Z07\\s("+nameofwave(Grad3HistWave)+") Flow [Intensity · Velocity]\r\\s("+nameofwave(Flow3HistWave)+") Flow Rate"	
		Legend/C/N=text0/J/A=MC "\\Z07\\s("+nameofwave(Grad2HistWave)+") Flow Rate\r\\s("+nameofwave(PV2HistWave)+") Protein Movement Speed"	
		DoWindow/C $HistWinName(15)
		//TextBox_ForceRoughHist_Info()		
	else
		DoWindow/F $HistWinName(15)
		//TextBox_ForceRoughHist_Info()
	endif
	KillWaves tempHist
	Killwaves FiltImgWave,temp_IntSigma,temp_Npnts		
	SetDataFolder curDF	
END

Function V_CheckRoughDir()
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(11), presentWindows)!=(-1))
		VEC9_TriDirection_Histo()
	endif
END

Function V_CheckFrcRoughDir()		//030813
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(14), presentWindows)!=(-1))
		VEC9_TriDirectionForce_Histo()
	endif
END

Function V_CheckBinaryRoughDir()		//060511
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(15), presentWindows)!=(-1))
		VEC9_BiDirectionForce_Histo()
	endif
END



// made for counting peaks**************************************************************************************

Function initializeDirAnalPara()		// original V9_initializeAnalysisFolder() is in VEC2Dhist_anal.ipf

	if (datafolderexists(":analysis")==0)
		V9_initializeAnalysisFolder()
	endif
	
		setdatafolder :analysis
		SVAR/z currentHistname//=:Analysis:currentHistname
	//	string test=currentHistname
		if (SVAR_Exists(currentHistname)==0)
			String/G currentHistname
		endif
		currenthistname="none"
	
		NVAR/z smMethod//=:analysis:smMethod
		if (NVAR_Exists(smMethod)==0)
			Variable/G smMethod
			NVAR smMethod
		endif	
		smMethod=2	
	
		NVAR/z SmoothMag//=:Analysis:SmoothMag
		if (NVAR_Exists(SmoothMag)==0)
			Variable/G SmoothMag
			NVAR SmoothMag
		endif	
		SmoothMag=0.5
		
		NVAR/z binGapThres//=:Analysis:binGapThres
		if (NVAR_Exists(binGapThres)==0)
			Variable/G binGapThres
			NVAR binGapThres
		endif	
		binGapThres=0.01

		NVAR/z Gap_sigma//=:Analysis:binGapThres
		if (NVAR_Exists(Gap_sigma)==0)
			Variable/G Gap_sigma
			NVAR Gap_sigma
		endif	
		Gap_sigma=0
			
		setdatafolder ::
END

Function xHistDir_PopMenuProc(ctrlName,popNum,popstr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popstr

	if (cmpstr(popstr,"root")==0)
		setdatafolder root:
	else
		setdatafolder $("root:"+popstr)
		controlupdate/A
	endif
//	SVAR/z currentHistname=:Analysis:currentHistname
////	string test=currentHistname
//	if (SVAR_Exists(currentHistname)==0)
//		String/G :analysis:currentHistname
//	endif	
//	currentHistname=popstr
//	wave currentHist=$currentHistname
//	string currentHist_sm_name=currentHistname+"sm"
//	Duplicate/O currenthist $currentHist_sm_name
End

Function xHistwaves_PopMenuProc(ctrlName,popNum,popstr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popstr

	SVAR/z currentHistname=:Analysis:currentHistname
//	string test=currentHistname
	if (SVAR_Exists(currentHistname)==0)
		String/G :analysis:currentHistname
	endif	
	currentHistname=popstr
	wave currentHist=$currentHistname
	string currentHist_sm_name=currentHistname+"sm"
	Duplicate/O currenthist $currentHist_sm_name
End

Function xSmMethod_PopMenuProc(ctrlName,popNum,popstr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popstr

	NVAR/z L_smMethod=:analysis:smMethod
	if (NVAR_Exists(L_smMethod)==0)
		Variable/G :analysis:smMethod
		NVAR L_smMethod=:analysis:smMethod
	endif
	L_smMethod=popnum
End

Function xSetSmDegreeProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR/z SmoothMag=:Analysis:SmoothMag
	if (NVAR_Exists(SmoothMag)==0)
		Variable/G :analysis:SmoothMag
		NVAR SmoothMag=:Analysis:SmoothMag
	endif	
	SmoothMag=varnum
End

Function xSetbinGapThresProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR/z binGapThres=:Analysis:binGapThres
	if (NVAR_Exists(binGapThres)==0)
		Variable/G :analysis:binGapThres
		NVAR binGapThres=:Analysis:binGapThres
	endif	
	binGapThres=varnum
End

Function xPanel_HistDoit(ctrlName) : ButtonControl
	String ctrlName

	SVAR/z currentHistname=:Analysis:currentHistname
	NVAR/z L_smMethod=:analysis:smMethod
	NVAR/z SmoothMag=:Analysis:SmoothMag	
	NVAR/z binGapThres=:Analysis:binGapThres

	if (numtype(L_smMethod)==2)
		L_smMethod=2
	endif
	if (numtype(SmoothMag)==2)
		Smoothmag=0.5
	endif
	if (numtype(binGapThres)==2)
		binGapThres=0.003
	endif

	if (SVAR_Exists(currentHistname) && NVAR_Exists(L_smMethod) && NVAR_Exists(binGapThres) && NVAR_Exists(SmoothMag))
		wave currentHist=$currentHistname
		string currentHist_sm_name=currentHistname+"sm"
		wave currentHist_sm=$currentHist_sm_name
		variable i,j,k
		variable Rowlength=dimsize(currenthist,0)
		switch (L_smMethod)
			case 1:
				for (j=0; j<rowlength; j+=1)
					if (j==rowlength-1)
							//i=j-1
							k=0
					else
					//	i=j-1
						k=j+1
					endif
					currenthist_sm[j]=(currenthist[j]+currenthist[k])/2
				endfor
			
				break
			case 2:
				for (j=0; j<rowlength; j+=1)
					if (j==0)
						i=rowlength-1
						k=j+1
					else 
						if (j==rowlength-1)
							i=j-1
							k=0
						else
							i=j-1
							k=j+1
						endif
					endif
					currenthist_sm[j]=(currenthist[j]+SmoothMag*(currenthist[i]+currenthist[k]))/(1+2*smoothMag)
				endfor
			
				break
			
			case 3:

				for (j=0; j<rowlength; j+=1)
					if (j==0)
						i=rowlength-1
						k=j+1
					else 
						if (j==rowlength-1)
							i=j-1
							k=0
						else
							i=j-1
							k=j+1
						endif
					endif
					currenthist_sm[j]=(currenthist[j]+1*(currenthist[i]+currenthist[k]))/3
				endfor
							
				break
				
			endswitch

			string currentHist_smGAP_name=currentHistname+"smGAP"
			string currentHist_smGAPo_name=currentHistname+"smGAPo"
			Duplicate/O currenthist_sm $currentHist_smGAP_name,$currentHist_smGAPo_name
			wave currentHist_smGAP=$currentHist_smGAP_name
			wave currentHist_smGAPo=$currentHist_smGAPo_name
			
			for (i=0; i<rowlength;i+=1)
				if (i<(rowlength-1))
					currentHist_smGAP[i]=currentHist_sm[i+1]-currentHist_sm[i]			
				else 
					currentHist_smGAP[i]=currentHist_sm[0]-currentHist_sm[i]
				endif
				currentHist_smGAPo[i]=currentHist_smGAP[i]
				if (abs(currentHist_smGAP[i])<binGapThres)
					currentHist_smGap[i]=0
				else
					currentHist_smGap[i]=sign(currentHist_smGap[i])
				endif	
			endfor
			string currentHist_smPEAK_name=currentHistname+"smPEK"
			Duplicate/O currenthist_sm $currentHist_smPEAK_name			
			wave currentHist_smPEAK=$currentHist_smPEAK_name
			for (i=0; i<rowlength;i+=1)
				if (i!=0)//<(rowlength-1))
					if ((currentHist_smGAP[i]-currentHist_smGAP[i-1]) ==-2)
						currentHist_smPEAK[i]=1
					else
						currentHist_smPEAK[i]=0
					endif			
				else 
					if ((currentHist_smGAP[0]-currentHist_smGAP[(rowlength-1)])==-2)//i]) ==-2)
						currentHist_smPEAK[0]=1
					else
						currentHist_smPEAK[0]=0
					endif			
				endif
			endfor
	xGap_sigma()
	controlupdate/A 		
	else
	
	
	endif			
End

Function xPanel_HistGap_sigma(ctrlName) : ButtonControl
	String ctrlName

//	SVAR/z currentHistname=:Analysis:currentHistname
////	wave currentHist=$currentHistname
////	string currentHist_sm_name=currentHistname+"sm"
////	wave currentHist_sm=$currentHist_sm_name
//	string currentHist_smGAP_name=currentHistname+"smGAP"
//	wave currentHist_smGAP=$currentHist_smGAP_name
////	string currentHist_smPEAK_name=currentHistname+"smPEK"
////	wave currentHist_smPEAK=$currentHist_smPEAK_name		
//	variable i
//	variable Gap_sigma=0
//	for (i=0; i<numpnts($currentHist_smGAP_name);i+=1)
//		Gap_sigma+=abs(currentHist_smGAP[i])
//	endfor

	print xGap_sigma()
end

Function xGap_sigma() 
	
		NVAR/z L_Gap_sigma=:Analysis:Gap_sigma
		if (NVAR_Exists(L_Gap_sigma)==0)
			Variable/G :Analysis:Gap_sigma
			//NVAR Gap_sigma
		endif	
		L_Gap_sigma=0
		
	SVAR/z currentHistname=:Analysis:currentHistname
	if (SVAR_exists(currentHistname)==1)	
		string currentHist_smGAPo_name=currentHistname+"smGAPo"
		wave/z currentHist_smGAPo=$currentHist_smGAPo_name
		variable i
		for (i=0; i<numpnts($currentHist_smGAPo_name);i+=1)
			L_Gap_sigma+=abs(currentHist_smGAPo[i])
		endfor
	endif
	printf "Gap_sigma is %g\r", L_Gap_sigma
	return L_Gap_sigma
end
		

END

Function/s datafoldrelist()
	variable i
	variable foldernumber=countObjects("",4)
	string DatafolderList=""
	for (i=0;i<foldernumber;i+=1)
		datafolderlist+=GetIndexedObjName("",4,i)+";"
	endfor
	datafolderlist+="root"
	return datafolderlist
END
		

END
Function Panel_Histanal() : panel
	initializeDirAnalPara()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(312.75,116,570,344.75)
	ModifyPanel cbRGB=(65534,65534,65534)
	//ShowTools
	SetDrawLayer UserBack
	DrawRect 9,7,213,217
	//DrawText 12,188,"Peak Number is "
	PopupMenu selectDIR,pos={20,13},size={152,21},proc= xHistDir_PopMenuProc,title="Directory"
	PopupMenu selectDIR,mode=1,popvalue="none",value= #"datafoldrelist()"
	
	PopupMenu popup_directory,pos={16,43},size={140,21},proc=xHistwaves_PopMenuProc,title="waves"
	PopupMenu popup_directory,mode=1,popvalue="none",value= #"WaveList(\"*degH\",\";\",\"\")"
	PopupMenu smMethod,pos={15,73},size={138,21},proc=xSmMethod_PopMenuProc,title="Smooth Bins"
	PopupMenu smMethod,mode=1,popvalue="2 bins",value= #"\"2 bins;1+2*0.5 bins;3 bins\""
	SetVariable setHistThres,pos={24,129},size={160,16},proc=xSetbinGapThresProc,title="Bin Gap Threshold "
	SetVariable setHistThres,format="%g"
	SetVariable setHistThres,limits={0,0.1,0.001},value= :Analysis:binGapThres
	Button dobutton,pos={132,153},size={50,20},proc=xPanel_HistDoit,title="Do It !"
	SetVariable SmoothVal,pos={24,102},size={110,16},proc=xSetSmDegreeProc,title="Smoothing:"
	SetVariable SmoothVal,format="%g"
	SetVariable SmoothVal,limits={0,1,0.1},value= :Analysis:SmoothMag
	NVAR/z gap_sigma=:analysis:Gap_Sigma
	ValDisplay gap_sigma,pos={14,195},size={100,15},title="Gap Sigma"
	ValDisplay gap_sigma,limits={0,0,0},barmisc={0,1000},value= #"gap_sigma" //xGap_sigma() "	
EndMacro

Function DisplayHistDiranalysis()

	SVAR/z currentHistname=:Analysis:currentHistname
//	NVAR/z L_smMethod=:analysis:smMethod
//	NVAR/z SmoothMag=:Analysis:SmoothMag	
//	NVAR/z binGapThres=:Analysis:binGapThres
//	if (SVAR_Exists(currentHistname) && NVAR_Exists(L_smMethod) && NVAR_Exists(binGapThres) && NVAR_Exists(SmoothMag))
	wave currentHist=$currentHistname
	string currentHist_sm_name=currentHistname+"sm"
	wave currentHist_sm=$currentHist_sm_name
	string currentHist_smGAP_name=currentHistname+"smGAP"
//	Duplicate/O currenthist_sm $currentHist_smGAP_name
	wave currentHist_smGAP=$currentHist_smGAP_name
	string currentHist_smPEAK_name=currentHistname+"smPEK"
//	Duplicate/O currenthist_sm $currentHist_smPEAK_name			
	wave currentHist_smPEAK=$currentHist_smPEAK_name				

	Display currentHist,currentHist_sm
	ModifyGraph rgb($currentHist_sm_name)=(0,15872,65280)
	AppendToGraph/R currentHist_smGAP,currentHist_smPEAK
	ModifyGraph mode($currentHist_smGAP_name)=3,marker($currentHist_smGAP_name)=8
	ModifyGraph rgb($currentHist_smGAP_name)=(0,15872,65280),mode($currentHist_smPEAK_name)=3
	ModifyGraph marker($currentHist_smPEAK_name)=19
	
			
END

//*****************

//060411 modified
Function V9_CollectFlowrateAllVecWin() //040121
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i,count
	count=0
	string prefix
	string FLnorm="HistWaves_flowratesNorm"
	string FL="HistWaves_flowrates"
	string PV="HistWaves_PV"
	
	if (DataFolderExists(FLnorm)==0)
		NewDataFolder $FLnorm
	endif
	if (DataFolderExists(FL)==0)
		NewDataFolder $FL
	endif
	if (DataFolderExists(PV)==0)
		NewDataFolder $PV
	endif

	string CurrentVecWinName,curFolderName
 	if (ItemsInList(presentWindows)>1)
  		for (i=0;i<ItemsInList(presentWindows);i+=1)
  			CurrentVecWinName=StringFromList(i, presentWindows)
  			curFolderName=V_rtnFolderNameFromVecWIn(CurrentVecWinName)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				SetToTopImageDataFolder()
				wave/z Grad3HistWave=$(StatnameProc("flw")+"dirH3")
				wave/z Grad3ProtVelHistWave=$(StatnameProc("flw")+"PVH3")
				SVAR wavename_pref
				if (i==0)
					prefix=wavename_pref
				endif		
//				Duplicate/o $(StatnameProc("flw")+"dirH3"),$("root:FlowRateWaves:"+StatnameProc("flw")+"dirH3")
//				Duplicate/o $(StatnameProc("flw")+"PVH3"),$("root:FlowRateWaves:"+StatnameProc("flw")+"PVH3")

				Duplicate/o $(StatnameProc("flw")+"dirH3"),$("root:"+FLnorm+":"+curFolderName+"_flw"+"dirH3")
				Duplicate/o $(StatnameProc("flw")+"PVH3"),$("root:"+PV+":"+curFolderName+"_flw"+"PVH3")
				Duplicate/o $(StatnameProc("flw")+"FRH3"),$("root:"+FL+":"+curFolderName+"_flw"+"FRH3")	//added 060406
			
				count+=1
			endif
		endfor

//		string AVEname,SDname,SEMname,Nname
//		AVEname=wavename_pref+"FRave"
//		SDname=wavename_pref+"FRsd"
//		SEMname=wavename_pref+"FRsem"
//		Nname=wavename_pref+"FRn"
//		Make/N=3 $AVEname,$SDname,$SEMname,$Nname
//		wave AVE=$AVEname
//		wave SD=$SDname
//		wave SEM=$SEMname
//		wave Nwave=$Nname
//		AVE[]=TempWave/count
		
	endif
	
	SetDataFolder curDF	
END

//060511 made
Function V9_CollectBinaryFRAllVecWin() 
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i,count
	count=0
	string prefix
	string FLnorm="HistWavesBin_flowratesNorm"
	string FL="HistWavesBin_flowrates"
	string PV="HistWavesBin_PV"
	
	if (DataFolderExists(FLnorm)==0)
		NewDataFolder $FLnorm
	endif
	if (DataFolderExists(FL)==0)
		NewDataFolder $FL
	endif
	if (DataFolderExists(PV)==0)
		NewDataFolder $PV
	endif

	string CurrentVecWinName,curFolderName
 	if (ItemsInList(presentWindows)>1)
  		for (i=0;i<ItemsInList(presentWindows);i+=1)
  			CurrentVecWinName=StringFromList(i, presentWindows)
  			curFolderName=V_rtnFolderNameFromVecWIn(CurrentVecWinName)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				SetToTopImageDataFolder()
				wave/z Grad2HistWave=$(StatnameProc("flw")+"dirH2")
				wave/z Grad3ProtVelHistWave=$(StatnameProc("flw")+"PVH2")
				SVAR wavename_pref
				if (i==0)
					prefix=wavename_pref
				endif		
//				Duplicate/o $(StatnameProc("flw")+"dirH3"),$("root:FlowRateWaves:"+StatnameProc("flw")+"dirH3")
//				Duplicate/o $(StatnameProc("flw")+"PVH3"),$("root:FlowRateWaves:"+StatnameProc("flw")+"PVH3")

				Duplicate/o $(StatnameProc("flw")+"dirH2"),$("root:"+FLnorm+":"+curFolderName+"_flw"+"dirH2")
				Duplicate/o $(StatnameProc("flw")+"PVH2"),$("root:"+PV+":"+curFolderName+"_flw"+"PVH2")
				Duplicate/o $(StatnameProc("flw")+"FRH2"),$("root:"+FL+":"+curFolderName+"_flw"+"FRH2")	//added 060406
			
				count+=1
			endif
		endfor

//		string AVEname,SDname,SEMname,Nname
//		AVEname=wavename_pref+"FRave"
//		SDname=wavename_pref+"FRsd"
//		SEMname=wavename_pref+"FRsem"
//		Nname=wavename_pref+"FRn"
//		Make/N=3 $AVEname,$SDname,$SEMname,$Nname
//		wave AVE=$AVEname
//		wave SD=$SDname
//		wave SEM=$SEMname
//		wave Nwave=$Nname
//		AVE[]=TempWave/count
		
	endif
	
	SetDataFolder curDF	
END



Function V9_Collect3DirectionAllVecWin() //040126
	String curDF=GetDataFolder(1)
	String presentWindows=WinList("VecField_*", ";", "" )
	setdatafolder root:
	variable i,count
	count=0
	string prefix
	if (DataFolderExists("Direction3Waves")==0)
		NewDataFolder Direction3Waves
	endif
	string CurrentVecWinName
 	if (ItemsInList(presentWindows)>1)
  		for (i=0;i<ItemsInList(presentWindows);i+=1)
  			CurrentVecWinName=StringFromList(i, presentWindows)
			DoWindow/F $CurrentVecWinName
			if (V_Flag)
				VEC9_TriDirection_Histo()
				DoWindow/F $CurrentVecWinName
				SetToTopImageDataFolder()
				wave/z Grad3HistWave=$(StatHISTnameProc("deg3"))
				SVAR wavename_pref
				if (i==0)
					prefix=wavename_pref
				endif		
				Duplicate/o $(StatHISTnameProc("deg3")),$("root:Direction3Waves:"+StatHISTnameProc("deg3")+"n"+num2str(i)+"dirH3")
				count+=1
			endif
		endfor
	
	endif
	
	SetDataFolder curDF	
END

//============== stats
// to use this, prepare 3or more waves with three rows (Away, Normal, towards) from a same sampling category and put those waves
//in a same datafolder. move to that data folder and execte the program. The results will be shown in the command history window.
//resulting t_value should be evaluated in comparison to the t distribution given in elsewhere.
// Form ZAR. see APP19 Statistical Values for the t distribution

Function Vec9_Ttest_cust(comparetype)
	variable comparetype		// 1 away-normal 2 away-towards 3 normal-towards
	variable i
	string MATlist=WaveList("*H", ";", "" )
	String CurrentH
	print MATList
	Variable ListNum=ItemsInList(MATlist)
	Make/O/N=(ListNum) temp1,temp2
	wave/z temp1,temp2
	for (i=0;i<listnum;i+=1)
		CurrentH=StringFromList(i,MATlist)
		wave srchist=$CurrentH	

		if (comparetype==1)
			temp1[i]=srchist[0]
			temp2[i]=srchist[1]
		else
			if (comparetype==2)
				temp1[i]=srchist[0]
				temp2[i]=srchist[2]
			else
				if (comparetype==3)
					temp1[i]=srchist[1]
					temp2[i]=srchist[2]
				endif
			endif
		endif
	endfor
	Vec9_twosample_t_tests(temp1,temp2)
	Killwaves temp1,temp2
END

Function Vec9_Ttest_custDo3Comp2(type)		//040121 automatically get stats for 3 directions, compare towards and away
	variable type 								//variable comparetype		
	variable i
	string MATlist
	if (type==0)
		MATlist=WaveList("*H", ";", "" )
	else
		MATlist=WaveList("*H3", ";", "" )
	endif
	String CurrentH
	print MATList
	Variable ListNum=ItemsInList(MATlist)
	Make/O/N=(ListNum) temp1,temp2,temp3
	wave/z temp1,temp2
	for (i=0;i<listnum;i+=1)
		CurrentH=StringFromList(i,MATlist)
		wave srchist=$CurrentH	

		temp1[i]=srchist[0]
		temp2[i]=srchist[1]
		temp3[i]=srchist[2]
	endfor
	String curDF=GetDataFolder(1)
	movewave temp1 root:
	movewave temp2 root:
	movewave temp3 root:
	SetDataFolder root:
	Vec9_twosample_t_testsSPEC(temp1,temp2,temp3)
	Killwaves temp1,temp2,temp3
	
	SetDataFolder curDF
END


// for histograms ending with H3, to process flow rate data and protein moving speed data.

Function Vec9_Ttest_custv2(comparetype)
	variable comparetype		// 1 away-normal 2 away-towards 3 normal-towards
	variable i
	string MATlist=WaveList("*H3", ";", "" )
	String CurrentH
	print MATList
	Variable ListNum=ItemsInList(MATlist)
	Make/O/N=(ListNum) temp1,temp2
	wave/z temp1,temp2
	for (i=0;i<listnum;i+=1)
		CurrentH=StringFromList(i,MATlist)
		wave srchist=$CurrentH	

		if (comparetype==1)
			temp1[i]=srchist[0]
			temp2[i]=srchist[1]
		else
			if (comparetype==2)
				temp1[i]=srchist[0]
				temp2[i]=srchist[2]
			else
				if (comparetype==3)
					temp1[i]=srchist[1]
					temp2[i]=srchist[2]
				endif
			endif
		endif
	endfor
	Vec9_twosample_t_tests(temp1,temp2)
	Killwaves temp1,temp2
END





Function Vec9_twosample_t_tests(srcwave1,srcwave2)
	wave srcwave1,srcwave2
	variable N1,N2,AVG1,AVG2,SS1,SS2
	wavestats/q srcwave1
	AVG1=V_avg
	N1=V_npnts
	wavestats/q srcwave2
	AVG2=V_avg
	N2=V_npnts

	SS1=VEC9_Stat_GetSS(srcwave1)
	SS2=VEC9_Stat_GetSS(srcwave2)

	variable S2p,SX1_X2,t_value
	S2p=(SS1+SS2)/(N1+N2-2)
	SX1_X2=sqrt(S2p/N1+S2p/N2)
	t_value=(AVG1-AVG2)/SX1_X2
	wavestats/q srcwave1
	printf "1st wave mean: %f sd: %f sem %f\r", V_avg,V_sdev,(V_sdev/sqrt(V_npnts))
	wavestats/q srcwave2
	printf "2nd wave mean: %f sd: %f sem %f\r", V_avg,V_sdev,(V_sdev/sqrt(V_npnts))
	printf "t_value is %f\r", abs(t_value)
	printf "v is %d\r", (N1+N2-2)
		printf "student T value 99.5 %g\r",studentT(0.995,(N1+N2-2))
		printf "student T value 99 %g\r",studentT(0.99,(N1+N2-2))
		printf "student T value 95 %g\r",studentT(0.95,(N1+N2-2))
		printf "probablility %g\r", StudentA(t_value, (N1+N2-2))		
	return t_value
END

Function Vec9_twosample_t_testsSPEC(srcwave1,srcwave2,srcwave3) //040121
	wave srcwave1,srcwave2,srcwave3
	variable N1,N2,N3,AVG1,AVG2,AVG3,SS1,SS2,SS3
	String WavePrefix
	Prompt WavePrefix, "Result Wave Name prefix?"
	DoPrompt "Enter Name:",WavePrefix
	if (V_flag)
		Abort "Processing Canceled"
	endif
	String WavesListed=NameofWave(srcwave1)+";"+NameofWave(srcwave2)+";"+NameofWave(srcwave3)+";"
	String SDwavename,SEMwavename,Nwavename
	SDwavename=WavePrefix+"_sd"
	SEMwavename=WavePrefix+"_sem"
	Nwavename=WavePrefix+"_n"
	Make/O/N=3 $WavePrefix,$SDwavename,$SEMwavename,$Nwavename
	wave/z AVEwave=$WavePrefix
	wave/z SDwave=$SDwavename
	wave/z SEMwave=$SEMwavename
	wave/z Nwave=$Nwavename
	variable i
	string currentwavename
	for (i=0;i<3;i+=1)
		wave/z currentwave=$(StringFromList(i, WavesListed))
		wavestats/q currentwave
		//AVG1=V_avg
		//N1=V_npnts
		AVEwave[i]=V_avg
		SDwave[i]=V_sdev
		Nwave[i]=V_npnts
		SEMwave[i]=(V_sdev/sqrt(V_npnts))
		printf "wave%d mean: %f sd: %f sem %f\r",(i+1), V_avg,V_sdev,SEMwave[i]
	endfor

	SS1=VEC9_Stat_GetSS(srcwave1)
	SS2=VEC9_Stat_GetSS(srcwave2)
	SS3=VEC9_Stat_GetSS(srcwave3)
	
	variable S2p,SX1_X2,t_value
	S2p=(SS1+SS3)/(Nwave[0]+Nwave[2]-2)
	SX1_X2=sqrt(S2p/Nwave[0]+S2p/Nwave[2])
	t_value=(AVEwave[0]-AVEwave[2])/SX1_X2
	
	edit $WavePrefix,$SDwavename,$SEMwavename,$Nwavename
	V9_GraphFlowRateCollected(AVEwave,SEMwave)	//040122 see below
	printf "1st wave-3rd wave: t_value is %f\r", abs(t_value)
	printf "1st wave-3rd wave: v is %d\r", (Nwave[0]+Nwave[2]-2)
	return t_value
	
END

Function V9_GraphFlowRateCollected(srcwave,srcwave_sem)
	wave srcwave,srcwave_sem
	setdatafolder root:
	Make/O/N=3/T Direction
	Direction={"Away","Normal","Towards"}
	Display $(NameofWave(srcwave)) vs Direction
	ModifyGraph width=200,height={Aspect,1.2}
	SetAxis left 0,0.45 
	Label left "Protein Flow Rate [arb]"
	Label bottom "Direction"
	ErrorBars $(Nameofwave(srcwave)) Y,wave=($(Nameofwave(srcwave_sem)),$(Nameofwave(srcwave_sem)))
	ModifyGraph lsize=0.5
	ModifyGraph catGap(bottom)=0.3
	Legend/C/N=text0/A=MT
END



Function VEC9_Stat_GetSS(srcwave)
	wave srcwave
	wavestats/q srcwave
	Variable SS=0
	Variable i
	for (i=0;i<numpnts(srcwave);i+=1)
		SS+=(srcwave[i]-V_avg)^2
	endfor
	return SS
END

//	wave currentHist_sm=$currentHist_sm_name

//
//	String	L_wavename_pref
//	String 	Pref=V_Prefix()
//	setdatafolder root:
//	prompt	L_wavename_pref, "Prefix of the TIFF files?", popup  WaveList(Pref+"*",";","")


////030811 --------------- for statistics T test between Towards and Away
Function V_getSS(sd,npt)
	variable sd,npt
	return (sd)^2 * (npt-1)
END

// get t-value from a set of Mean value, s.d. & number of points
Function V_statTfromMeanSD(Mean1,Sd1,npt1,Mean2,Sd2,npt2)
	Variable Mean1,Sd1,npt1,Mean2,Sd2,npt2
	variable SS1,SS2,S2p,Sxx,tval
	SS1=V_getSS(Sd1,npt1)
	SS2=V_getSS(Sd2,npt2)
	S2p = (SS1 + SS2)/(npt1+npt2-2)
	Sxx=(S2p/npt1 + S2p/npt2 )^ 0.5
	tval=(Mean1-Mean2)/Sxx
	return tval
END

//030811			for deriving Mean and Standard deviation from waves of, Mean+- s.d. (n) data

Function V_calcMeanSD(mean_wave,sd_wave,npt_wave)
	wave mean_wave,sd_wave,npt_wave
	variable MeanALL,MeanALLpnts,MSall,SDall
	MeanALL=0
	MeanALLpnts=0
	MSall=0
	variable i
	for (i=0;i<numpnts(mean_wave);i+=1)
		MeanALL+=mean_wave[i]*npt_wave[i]
		MSall+=(npt_wave[i]-1)*(sd_wave[i])^2
		MeanALlpnts+=npt_wave[i]
	endfor
	MeanALL/=MeanALLpnts
	SDall=(MSall/(MeanALLpnts-1))^0.5
	printf "Summary of all data:\r Mean %g ±%g (s.d.) n =%g",MeanALL,SDall,MeanALLpnts
END

//060410 see p162 Zar
Function Vec9_pairedsample_t_tests(srcwave1,srcwave2)
	wave srcwave1,srcwave2
	variable N1,N2,AVG1,AVG2,SS1,SS2
	wavestats/q srcwave1
	AVG1=V_avg
	N1=V_npnts
	wavestats/q srcwave2
	AVG2=V_avg
	N2=V_npnts

	variable AVG_difference, SD_difference, SEM_difference

	variable t_value
	if (N1==N2)
		make/o/n=(N1) tempDifference
		tempDifference[]=srcwave1[p]-srcwave2[p]
	
		SS1=VEC9_Stat_GetSS(tempDifference)
		wavestats/q tempDifference
		AVG_difference=V_avg
		SD_difference=V_sdev
		SEM_difference=V_sdev/(V_npnts)^0.5
		t_value=AVG_difference/SEM_difference
		
		wavestats/q srcwave1
		printf "1st wave mean: %f sd: %f sem %f\r", V_avg,V_sdev,(V_sdev/sqrt(V_npnts))
		wavestats/q srcwave2
		printf "2nd wave mean: %f sd: %f sem %f\r", V_avg,V_sdev,(V_sdev/sqrt(V_npnts))
		printf "t_value is %f\r", abs(t_value)
		printf "v is %d\r", (N1-1)
		printf "student T value 99.5 %g\r",studentT(0.995,(N1-1))
		printf "student T value 99 %g\r",studentT(0.99,(N1-1))
		printf "student T value 95 %g\r",studentT(0.95,(N1-1))
		printf "probablility %g\r", StudentA(t_value, (N1-1) )	
		killwaves tempDifference	
	else
		printf "paired test must be done with same sample size for two populations\r"
	endif	
	return t_value
END
	
	
