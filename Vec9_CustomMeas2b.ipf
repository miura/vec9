#pragma rtGlobals=1		// Use modern global access method.

//analysis functions
// set Velocity range to either 0 ~ 2, 2.5 or 3 pixels/ frame and get the deviations		030218
//V9_SetRangeGetDev(maxV)

 //V9_FindRangeSet_summarize()		//030218			for making graphs (Vmax and Vslope range finding)
 
//reformed version of Function DoAllwithDifInt(direction,rangeV,rangeG) 030212
 //SummarizeDirection(rangeG)			//030219
 

// *********************** filename retrieve for the batch processing

// converting loop number to dot size (since dot size is not periodically defined)
Function V9_dotsizeCorrection(LoopNum)
	variable loopnum
	variable Gdotsize
	switch (Loopnum)
		case 0:
			Gdotsize=2
			break
		case 1:
			Gdotsize=4
			break
		case 2:
			Gdotsize=6
			break
		case 3:
			Gdotsize=8
			break
		case 4:
			Gdotsize=10
			break
		case 5:
			Gdotsize=20
			break
	endswitch
	//print Gdotsize
	return Gdotsize

END

Function V9_returnAngles(i)
	variable i
	variable direction
	switch(i)	// numeric switch
		case 0:		
			direction=0
			break					
		case 1:		
			direction=30
			break					
		case 2:		
			direction=45
			break					
		case 3:		
			direction=70
			break					
		case 4:		
			direction=90
			break					
	endswitch
	return direction	
END

Function V9_returnIntensities(i)
	variable i
	variable int
	switch(i)	// numeric switch
		case 0:		
			//int=15
			int=55		//for noise added sequences
			break					
		case 1:		
			int=55
			break					
		case 2:		
			int=115
			break					
		case 3:		
			int=175
			break					
		case 4:		
			int=215
			break
		case 5:		
			int=255
			break									
	endswitch
	return int	
END


Function/s V9_GenFileSuf(intensity,direction,dotsize,velocity)
	variable intensity,direction,dotsize,velocity
	string filename
	filename="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2Str(velocity)
	//print filename
	return filename
end

// set Velocity range to either 0 ~ 2, 2.5 or 3 pixels/ frame and get the deviations		030218

Function V9_linearFitSetRangeGetDev(srcwave,maxV)//,PrThres)
	wave srcwave
	variable maxV
	variable maxP=maxV/0.2
	wave/z W_coef
	NVAR/z r_v
	if (NVAR_exists(r_v)==0)
		variable/g r_v
	endif
	CurveFit/Q/H="10" line srcwave[0,maxP] /D
 	//printf "r_value=%f  ",V_Pr
 	r_v=V_Pr
 	//printf "slope = %f\r",(W_coef[1])
 	return V_chisq
END

Function V9_SetRangeGetDev(maxV)
	variable maxV
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string fitwavename,VMregname,VMslopename
	variable size,direction,intensity
	variable i,j,k
//=0.97
	NVAR/z maxpnt
	for (k=0;k<6;k+=1)
		size=V9_dotsizeCorrection(k)
		for (j=0;j<3;j+=1)
			direction= V9_returnAngles(j)
			VMregname="Vreg"+"D"+num2Str(direction)+"S"+num2Str(size)
			VMslopename="Vslp"+"D"+num2Str(direction)+"S"+num2Str(size)
			Make/O/N=6 $VMregname,$VMslopename 
			//print VMregname
			wave/z VMreg=$VMregname
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
				//Display $VMstatwavename
				//Dowindow/c tempWin
				//V9_linearFitFindRange(srcwave,PrThres)
				V9_linearFitSetRangeGetDev(srcwave,maxV)
				wave/z W_coef
				NVAR/z V_Pr
				NVAR/z V_chisq
				NVAR/z r_v
//				printf "2range max=%f\r",maxpnt
				VMreg[i]=r_v//V_Pr//V_chisq
				VMslope[i]=W_coef[1]
				wave/z fitwave=$fitwavename
				//Dowindow/k tempWin
				killwaves/z $fitwavename
			endfor
		endfor
	endfor
	V9_FindRangeSet_summarize()
	DoWindow/f VelocityRegression_slp_rangeSet
	TextBox/C/N=text1 "\\Z08Range 0 ~ "+num2str(maxV)+" [pix/frame]"	
	DoWindow/f VelocityRegression_r_rangeSet
	TextBox/C/N=text1 "\\Z08Range 0 ~ "+num2str(maxV)+" [pix/frame]"		
		
END



Function V9_FindRangeSet_summarize()		//030218			for making graphs (Vmax and Vslope range finding)
//	variable PrThres
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string fitwavename,VMregname,VMslpname
	variable size,direction,intensity
	variable i,j,k
//=0.97
	string VMregAV00="Vreg"+"D0"
	string VMregAV30="Vreg"+"D30"
	string VMregAV45="Vreg"+"D45"
	string VMregAV00sd="Vreg"+"D0sd"
	string VMregAV30sd="Vreg"+"D30sd"
	string VMregAV45sd="Vreg"+"D45sd"
	string VMslpAV00="Vslp"+"D0"
	string VMslpAV30="Vslp"+"D30"
	string VMslpAV45="Vslp"+"D45"
	string VMslpAV00sd="Vslp"+"D0sd"
	string VMslpAV30sd="Vslp"+"D30sd"
	string VMslpAV45sd="Vslp"+"D45sd"

	Make/O/N=6 $VMregAV00,$VMregAV30,$VMregAV45,$VMregAV00sd,$VMregAV30sd,$VMregAV45sd
	Make/O/N=6 $VMslpAV00,$VMslpAV30,$VMslpAV45,$VMslpAV00sd,$VMslpAV30sd,$VMslpAV45sd
	wave/z VMregD00=$VMregAV00,VMregD30=$VMregAV30,VMregD45=$VMregAV45
	wave/z VMregD00sd=$VMregAV00sd,VMregD30sd=$VMregAV30sd,VMregD45sd=$VMregAV45sd
	wave/z VMslpD00=$VMslpAV00,VMslpD30=$VMslpAV30,VMslpD45=$VMslpAV45
	wave/z VMslpD00sd=$VMslpAV00sd,VMslpD30sd=$VMslpAV30sd,VMslpD45sd=$VMslpAV45sd	

	NVAR/z maxpnt
	for (k=0;k<6;k+=1)
		size=V9_dotsizeCorrection(k)
		for (j=0;j<3;j+=1)
			direction= V9_returnAngles(j)
			VMregname="Vreg"+"D"+num2Str(direction)+"S"+num2Str(size)
			VMslpname="Vslp"+"D"+num2Str(direction)+"S"+num2Str(size)
			//Make/O/N=6 $VMrangeMax,$VMslopename 
			wave/z VMreg=$VMregname
			wave/z VMslp=$VMslpname
//			wavestats/q VMslp
			wavestats/q VMreg
			switch(direction)	
				case 0:		
					VMregD00[k]=V_avg
					VMregD00sd[k]=V_sdev
					break						
				case 30:		
					VMregD30[k]=V_avg
					VMregD30sd[k]=V_sdev
					break						
				case 45:		
					VMregD45[k]=V_avg
					VMregD45sd[k]=V_sdev
					break						
			endswitch
			wavestats/q VMslp
			switch(direction)	
				case 0:		
					VMslpD00[k]=V_avg
					VMslpD00sd[k]=V_sdev
					break						
				case 30:		
					VMslpD30[k]=V_avg
					VMslpD30sd[k]=V_sdev
					break						
				case 45:		
					VMslpD45[k]=V_avg
					VMslpD45sd[k]=V_sdev
					break						
			endswitch
		endfor
	endfor
	
	Dowindow/f VelocityRegression_r_rangeSet
	if (V_flag==0)
		Display $VMregAV00,$ VMregAV30,$ VMregAV45 vs Dotsize
		ErrorBars $VMregAV00 Y,wave=($VMregAV00sd,$VMregAV00sd)
		ErrorBars $VMregAV30 Y,wave=($VMregAV30sd,$VMregAV30sd)
		ErrorBars $VMregAV45 Y,wave=($VMregAV45sd,$VMregAV45sd)
		ModifyGraph grid(left)=1,tick=2
		SetAxis/A/E=1 bottom
		Dowindow/c VelocityRegression_r_rangeSet
	endif	
	DoWindow/f VelocityRegression_slp_rangeSet
	if (V_flag==0)
	
		Display $VMslpAV00,$ VMslpAV30,$ VMslpAV45 vs Dotsize
		ErrorBars $VMslpAV00 Y,wave=($VMslpAV00sd,$VMslpAV00sd)
		ErrorBars $VMslpAV30 Y,wave=($VMslpAV30sd,$VMslpAV30sd)
		ErrorBars $VMslpAV45 Y,wave=($VMslpAV45sd,$VMslpAV45sd)
		ModifyGraph grid(left)=1,tick=2
		SetAxis/A/E=1 bottom
			//SetAxis left 0,10 
		DoWindow/c VelocityRegression_slp_rangeSet		
	endif
END

//************************** Directionality Summarizing ************************************************

//reformed version of Function DoAllwithDifInt(direction,rangeV,rangeG) 030212
Function SummarizeDirectionChild(direction,rangeV,rangeG)				//030219
	variable direction,rangeV,rangeG
	variable i
	
//	string DotSizeVSrangeVMINwavename
//	string DotSizeVSrangeVMAXwavename
	string DotSizeVSrangeGMINwavename
	string DotSizeVSrangeGMAXwavename

//	string velocity_range="velocity_range"+num2str(direction)
	string direction_range="direction_range"+num2str(direction)
	string direction_rangeSD="direction_rangeSD"+num2str(direction)
	string suffix_d
//	Make/O/N=6 $direction_range,$direction_range
//	wave/z DR=$direction_range,DRsd=$direction_range
	for (i=0;i<6;i+=1)
		DoAllDotSizeSameInt(V9_returnIntensities(i),direction,rangeV,rangeG)
		suffix_d="I"+num2str(V9_returnIntensities(i))//+"D"+num2Str(direction)		
//		DotSizeVSrangeVMINwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
//		DotSizeVSrangeVMAXwavename="dVSrangeV"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"
		DotSizeVSrangeGMINwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
		DotSizeVSrangeGMAXwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"

//		wave/z DotSizeVSrangeVMAXwave=$DotSizeVSrangeVMAXwavename
//		wave/z DotSizeVSrangeVMINwave=$DotSizeVSrangeVMINwavename
		wave/z DotSizeVSrangeGMAXwave=$DotSizeVSrangeGMAXwavename
		wave/z DotSizeVSrangeGMINwave=$DotSizeVSrangeGMINwavename			
//		DoWindow/f	$velocity_range
//		if (V_flag==0)
//			Display DotSizeVSrangeVMINwave vs dotsize
//			Dowindow/C $velocity_range
//			appendtograph DotSizeVSrangeVMAXwave vs dotsize
//			Display DotSizeVSrangeGMINwave vs dotsize
//			Dowindow/C $direction_range
//			appendtograph DotSizeVSrangeGMAXwave vs dotsize
//		else
//			appendtograph DotSizeVSrangeVMINwave vs dotsize
//			appendtograph DotSizeVSrangeVMAXwave vs dotsize
//			Dowindow/F $direction_range
//			appendtograph DotSizeVSrangeGMINwave vs dotsize
//			appendtograph DotSizeVSrangeGMAXwave vs dotsize
//		endif
		
	endfor
	
END

Function SummarizeDirection(rangeG)			//030219
	variable rangeG
	variable rangeV=0.3

	variable direction
	string suffix_d
	variable i,j,k,l

	for (i=0;i<3;i+=1)
		direction=V9_returnAngles(i)
		SummarizeDirectionChild(direction,rangeV,rangeG)
	endfor
	
	string DotSizeVSrangeGMINwavename
	string DotSizeVSrangeGMAXwavename
	
	string direction_rangeMin,direction_rangeMax//="direction_range"+num2str(direction)
	string direction_rangeMinSD,direction_rangeMaxSD//="direction_rangeSD"+num2str(direction)
	for (i=0;i<3;i+=1)	//direction Loop
		direction=V9_returnAngles(i)
		direction_rangeMin="direction_rangeMin"+num2str(direction)
		direction_rangeMinSD="direction_rangeMinSD"+num2str(direction)
		direction_rangeMax="direction_rangeMax"+num2str(direction)
		direction_rangeMaxSD="direction_rangeMaxSD"+num2str(direction)

		Make/O/N=6 $direction_rangeMin,$direction_rangeMinSD
		Make/O/N=6 $direction_rangeMax,$direction_rangeMaxSD
		wave/z DRmin=$direction_rangeMin,DRminsd=$direction_rangeMinSD	
		wave/z DRmax=$direction_rangeMax,DRmaxsd=$direction_rangeMaxSD	

		for (k=0;k<6;k+=1)	//dotsize loop
			Make/O/N=6 tempMax,tempMin		//row=intensity
			for (j=0;j<6;j+=1)	//intensity loop
				suffix_d="I"+num2str(V9_returnIntensities(j))		
				DotSizeVSrangeGMINwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"min"
				DotSizeVSrangeGMAXwavename="dVSrangeG"+suffix_d+"rV"+num2str(10*rangeV)+"rG"+num2str(rangeG)+"max"
				wave/z DotSizeVSrangeGMAXwave=$DotSizeVSrangeGMAXwavename		//row=dotsize
				wave/z DotSizeVSrangeGMINwave=$DotSizeVSrangeGMINwavename
				tempMax[j]=DotSizeVSrangeGMAXwave[k]			
				tempMin[j]=DotSizeVSrangeGMINwave[k]			
			endfor
			wavestats/q tempMax
			DRmax[k]=V_avg
			DRmaxsd[k]=V_sdev
			wavestats/q tempMin
			DRmin[k]=V_avg
			DRminsd[k]=V_sdev
			
		endfor
		DoWindow/f DirectionMax
//		if (V_flag==0)
//			display $direction_rangeMax vs dotsize
//			ErrorBars $direction_rangeMax Y,wave=($direction_rangeMaxSD,$direction_rangeMaxSD)
//			DoWindow/c DirectionMax
//		else
//			appendtograph $direction_rangeMax vs dotsize
//			ErrorBars $direction_rangeMax Y,wave=($direction_rangeMaxSD,$direction_rangeMaxSD)
//		endif		
	endfor
 	killwaves tempMAX,tempMIN
END