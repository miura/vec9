#pragma rtGlobals=1		// Use modern global access method.

// these modules were writen for recording the stat values: average, sd, noise removed average, ...
// the waves to put the data should be made befor ethe recording starts. doing ROI stat automatically
// records data into the waves
 
Proc Name_ROIstat(statname)
	string statname
	NewDataFolder/O root:measure_para
	string/G root:measure_para:ROIstatname = statname
	variable/G root:measure_para:RoiStatMeasureFlag
	root:measure_para:RoiStatMeasureFlag=0
END

Function Name_ROIstat_dummy()
	string statname="dummy_wave"
	NewDataFolder/O root:measure_para
	string/G root:measure_para:ROIstatname = statname
	variable/G root:measure_para:RoiStatMeasureFlag=0
END

Function RoiStatMeasureFlag_ON()
	NVAR flag=root:measure_para:RoiStatMeasureFlag
	flag=1
END

Function RoiStatMeasureFlag_OFF()
	NVAR flag=root:measure_para:RoiStatMeasureFlag
	flag=0
END

//************************
Function Make_ROIstat_toWave()
	SVAR statwavename=root:measure_para:ROIstatname
	//String statwavename="dot01"
	String statwavenameAVG="root:"+statwavename+"AVG"
	String statwavenameAVGsd="root:"+statwavename+"AVGsd"
	String statwavenameAVGpnts="root:"+statwavename+"AVGpnts"
	String statwavenamecAVG="root:"+statwavename+"cAVG"
	String statwavenamecAVGpnts="root:"+statwavename+"cAVGpnts"
	if (waveexists($statwavenameAVG) ==1)
		print "wave already exists"
		print statwavename
	else
		Make/N=2/D $statwavenameAVG
		Make/N=2/D $statwavenameAVGsd
		Make/N=2/D $statwavenameAVGpnts
		Make/N=2/D $statwavenamecAVG
		Make/N=2/D $statwavenamecAVGpnts
	endif
	NVAR flag=root:measure_para:RoiStatMeasureFlag
	if (flag==1)
		Edit  $statwavenameAVG,$statwavenameAVGsd,$statwavenameAVGpnts,$statwavenamecAVG,$statwavenamecAVGpnts
	endif
END

Function Edit_RoiStatWaves()

	SVAR statwavename=root:measure_para:ROIstatname
	//String statwavename="dot01"
	String statwavenameAVG="root:"+statwavename+"AVG"
	String statwavenameAVGsd="root:"+statwavename+"AVGsd"
	String statwavenameAVGpnts="root:"+statwavename+"AVGpnts"
	String statwavenamecAVG="root:"+statwavename+"cAVG"
	String statwavenamecAVGpnts="root:"+statwavename+"cAVGpnts"

	Edit  $statwavenameAVG,$statwavenameAVGsd,$statwavenameAVGpnts,$statwavenamecAVG,$statwavenamecAVGpnts

END	

//***************************************
Function ROIstat_toWave(AVG,AVGsd,AVGpnts,cAVG,cAVGpnts)
	Variable AVG,AVGsd,AVGpnts,cAVG,cAVGpnts
	if (!dataFolderExists("root:measure_para"))
		Name_ROIstat_dummy()
		Make_ROIstat_toWave()
		print "ROI measure folder made"
	endif
	NVAR flag=root:measure_para:RoiStatMeasureFlag
	if (flag==1)
		SVAR statwavename=root:measure_para:ROIstatname
//		String statwavename="dot01"
		String statwavenameAVG="root:"+statwavename+"AVG"
		String statwavenameAVGsd="root:"+statwavename+"AVGsd"
		String statwavenameAVGpnts="root:"+statwavename+"AVGpnts"
		String statwavenamecAVG="root:"+statwavename+"cAVG"
		String statwavenamecAVGpnts="root:"+statwavename+"cAVGpnts"
	
		Wave/z waveAVG=$statwavenameAVG
		Wave/z waveAVGsd=$statwavenameAVGsd
		Wave/z waveAVGpnts=$statwavenameAVGpnts
		Wave/z wavecAVG=$statwavenamecAVG
		Wave/z wavecAVGpnts=$statwavenamecAVGpnts
		Variable pointnumber=0
		Variable current_point=0
		if (numpnts(waveAVG)<3)
			if ((waveAVG[0]==0) && (waveAVG[1]==0))
				pointnumber=0
			else
				pointnumber=1
				InsertPoints 1,1, waveAVG
				InsertPoints 1,1, waveAVGsd
				InsertPoints 1,1, waveAVGpnts		
				InsertPoints 1,1, wavecAVG
				InsertPoints 1,1, wavecAVGpnts		
			endif
			waveAVG[pointnumber] = AVG
			waveAVGsd[pointnumber] = AVGsd
			waveAVGpnts[pointnumber] = AVGpnts	
			wavecAVG[pointnumber] = cAVG
			wavecAVGpnts[pointnumber] = cAVGpnts
		else
			current_point=(numpnts(waveAVG)-1)
			waveAVG[current_point]=AVG
			waveAVGsd[current_point]=AVGsd
			waveAVGpnts[current_point]=AVGpnts	
			wavecAVG[current_point]=cAVG
			wavecAVGpnts[current_point]=cAVGpnts
			InsertPoints (current_point+1),1, waveAVG
			InsertPoints (current_point+1),1, waveAVGsd
			InsertPoints (current_point+1),1, waveAVGpnts		
			InsertPoints (current_point+1),1, wavecAVG
			InsertPoints (current_point+1),1, wavecAVGpnts		

		endif
	endif
END		