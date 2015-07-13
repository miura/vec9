#pragma rtGlobals=1		// Use modern global access method.

//**************************************************
Function LoadTIFFsequence()
	Variable filenum=100
	prompt filenum, "How many frames?"
	String pathname
	Prompt pathname, "Path name?", popup  PathList("*",";","")
	String wavename_pref
	prompt wavename_pref, "Name of the Tiff sequence?"
	DoPrompt "Enter Parameters for Loading the Tiff sequence",wavename_pref, pathname,filenum
	if (V_flag)
		Abort "Processing Canceled"
	endif

	Variable n
	String w,filename,currentwavename,firstwavename,originalTIFname,matrixname

	setdatafolder root:
	n=0
	do
			if (n >= filenum)
				break
			endif
			if (n<10)
				w="00"+num2str(n)
			endif
			 if ((10<=n) %& (n<100))
			 w="0"+num2str(n)
			 endif
			  if (100<=n)
			  w=num2str(n)
			endif 

			originalTIFname="Mat"+wavename_pref+w
			filename=wavename_pref+w+".tif"
			ImageLoad/T=Tiff /N=$originalTIFname/P=$pathname filename
			Wave wavenamea=$originalTIFname
			
			if (n==0)
				matrixname="Mat"+wavename_pref
				Redimension/N=(-1,-1,filenum) wavenamea
				Rename  wavenamea $matrixname					
				Wave originalMatrix=$matrixname
			else
				originalMatrix[][][n]=wavenamea[p][q]
				Killwaves wavenamea
			endif
			n=n+1
	while (n<filenum)
End

//**************************************************
//still not working. only 3 layers be imported.
Function LoadTIFFstack()
	Variable filenum=100
	prompt filenum, "How many frames?"
	String pathname
	Prompt pathname, "Path name?"
	String wavename_pref
	prompt wavename_pref, "Name of the Tiff sequence?"
	DoPrompt "Enter Parameters for Loading the Tiff sequence",wavename_pref, pathname//,filenum
	if (V_flag)
		Abort "Processing Canceled"
	endif

	Variable n
	String w,filename,currentwavename,firstwavename,originalTIFname,matrixname

	setdatafolder root:

	originalTIFname="Mat"+wavename_pref
	
	ImageLoad/C=500/S=0/N=$originalTIFname/P=$pathname wavename_pref

End

//**in the folowing, pop up dialogue interactively defines which wave to load (020326)
Function LoadTIFFstackV2()
	setdatafolder "root:"
	ImageLoad/T=tiff/S=0 /C=-1
	print V_flag
	if (V_flag!=1)
		Abort "Processing Canceled"
	endif	
	RenameTiffToMATNew(S_waveNames) 
END

Function V9_Save3Dmatrix_as_2Dbmpseq()
	setdatafolder root:
	String	matrix3Dname
	prompt	matrix3Dname, "which matrix?", popup  WaveList("Mat*",";","")
	String	path
	prompt	path, "path?", popup  pathlist("*",";","")
	Doprompt "3Dwave",matrix3Dname,path
	wave matrix3D=$matrix3Dname
	variable iteration=dimsize(matrix3D,2)
	Make/O/N=(dimsize(matrix3d,0),dimsize(matrix3d,1)) temp2D
	string filename=matrix3Dname
	string numbering 
	variable i,j
	for (i=0; i<iteration;i+=1)
		temp2D[][]=matrix3D[p][q][i]
		sprintf numbering "%4.0f",i
		filename=matrix3Dname+numbering+".bmp"
		imagesave/D=8/T="BMPf"/P=$path temp2D filename
	endfor	
END

Function/s RenameTiffToMAT()
	String MATlist
	Matlist=WaveList("*.tif", ";", "" )
	Variable n= ItemsInList(Matlist)
	variable i
	variable namelength
	string imagename,newimagename
	for (i=0; i<n; i+=1)
		imagename=StringFromList(i,MATlist)
		newimagename="MAT"+imagename[0,(strlen(imagename)-5)]
		rename $imagename,$newimagename
	endfor
	return newimagename
END

Function/s RenameTiffToMATNew(tif_filename)
	String tif_filename
	string newimagename
	if (cmpstr(tif_filename,"")==0)
		abort "no tif name"
	endif
	tif_filename=tif_filename[0,(strlen(tif_filename)-3)]
	print tif_filename
//	newimagename="MAT"+tif_filename[0,(strlen(tif_filename)-5)]
	newimagename="MAT"+tif_filename[0,(strlen(tif_filename)-6)]	
	rename $tif_filename,$newimagename
	return newimagename
END

//************************************* LOADING MASK binary image
//*** 020827

Function LoadMASKTIFF()
	setdatafolder "root:"
	ImageLoad/T=tiff/S=0 /C=1
	if (V_flag!=1)
		Abort "Processing Canceled"
	endif		
	RenameTiffToMASK(S_waveNames)
END

Function RenameTiffToMASKOLD()
	String maskList=WaveList("*.tif",";","")
	String	maskWaveName
	prompt	maskWaveName, "Prefix of the TIFF files?", popup maskList  
	DoPrompt "Which Tiff Image for masking?", maskWaveName
	string newimagename
	if (V_flag)
		Abort "Processing Canceled"
	endif
	newimagename="MSK"+maskWaveName[0,(strlen(maskWaveName)-5)]
	rename $maskWaveName,$newimagename
	wave/z MaskWave=$newimagename
	V_Convrt8bitToBinary(MaskWave)		//030728
END

Function RenameTiffToMASK(maskWaveName)
	String maskWaveName
	wave/z MaskWave=$(maskWaveName[0,(strlen(maskWaveName)-3)])
	string newimagename
//	if (V_flag)
//		Abort "Processing Canceled"
//	endif
//	newimagename="MSK"+maskWaveName[0,(strlen(maskWaveName)-7)]
	newimagename="MSK"+maskWaveName[0,(strlen(maskWaveName)-8)]	
	duplicate/o $(nameofwave(MaskWave)),$newimagename
	killwaves MaskWave
	wave/z MaskWave=$newimagename
	V_Convrt8bitToBinary(MaskWave)		//030728
END


Function/S V9_viewMaskedImg()			//020901
	String curDF=GetDataFolder(1)
	SetDataFolder "root:"
	String maskList=WaveList("MSK*",";","")
	String	maskWaveName
	prompt	maskWaveName, "Prefix of the TIFF files?", popup maskList  
	DoPrompt "Which Tiff Image for masking?", maskWaveName
//	wave maskwave=$maskWaveName
//	VEC_MaskedStat(maskwave)
	wave maskwave=$maskwavename
	Display;AppendImage maskWave
	ModifyGraph width=100,height={Plan,1,left,bottom}
	ModifyGraph margin(left)=15,margin(bottom)=15,margin(top)=0,margin(right)=0	
	ModifyGraph tick=3,nticks=2,fSize=7
	maskWaveName="root:"+maskWaveName
	return maskWaveName
	SetDataFolder curDF
END

Function InvertBinMASK()
	String curDF=GetDataFolder(1)
	SetDataFolder "root:"
	String maskList=WaveList("MSK*",";","")
	String	maskWaveName
	prompt	maskWaveName, "Prefix of the TIFF files?", popup maskList  
	DoPrompt "Which Tiff Image for masking?", maskWaveName
	wave maskwave=$maskwavename	
	V_InvertBinary(MaskWave)		//030728
END

//***************************************

Function DoalltoshowVectorField()
	String	L_wavename_pref
	setdatafolder root:
	prompt	L_wavename_pref, "Prefix of the TIFF files?", popup  WaveList("Mat*",";","")
	Variable	L_unit=3
	prompt	L_unit, "What is the size for the gradient detection? (2 or 3)", popup "3;2;"
	Variable	L_LayerStart=0
	prompt	L_LayerStart, "Starting Layer No.?"
	Variable	L_LayerEnd=9
	Prompt	L_LayerEnd, "Ending Layer No.?"
	Variable L_averaging
	Prompt L_averaging, "How Many Pixels for Averaging?", popup "3;5;7;9;11;13;15;17;19;21;23;"
	Variable L_scale=25
	Prompt L_scale, "Scaling of the vector:" 
	Variable L_button_bleachcorrect=0
	Prompt L_button_bleachcorrect, "Bleaching Correction:",popup "off;Linear_Fit;Raw_Values" 
	Variable L_OptimizationMethod=0
	Prompt L_OptimizationMethod, "Optimization Method:",popup "Temporal_Local;Spatial_Temporal_Local_3x3;Spatial_Temporal_Local_5x5" 
	Doprompt "Input Parameters::",L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod

	if (V_flag)
		Abort "Processing Canceled"
	endif

	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])
	if (L_unit==1)
		L_unit=3
	elseif (L_unit==2)
		L_unit=2
	endif
	L_averaging =L_averaging*2+1	//correction for the popup menue	
	if (L_scale<1)
		L_scale=1
	endif
	L_button_bleachcorrect-=1	
	//printf "L_wavename_pref %s,L_unit %g,L_LayerStart %g,L_LayerEnd %g,L_averaging %g,L_scale %g,L_button_bleachcorrect %g,L_OptimizationMethod%g",L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod
	DoalltoshowVectorField_Core(L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod)
END

Function DoalltoshowVectorField_Core(L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod)
	String L_wavename_pref
	Variable L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod
	
	setdatafolder root:		//040121
	
	String	FolderName,L_windowname,WindowMatching
	String/G path			//string at the root directory

//-------------GetNames---------	
	
	L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
	//printf "Window Name: %s\r", L_windowname
	FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
	path=("root:"+Foldername)
	//printf "Folder Name: %s\r", FolderName
	WindowMatching=Winlist(L_windowname,";","")
	print windowmatching
	if (WhichListItem(L_windowname, WindowMatching)!=(-1))
		DoWindow/F  $L_windowname
		Print "Same Parameter as the previously shown plot"
	else
//-------------------------------------------
		if (DataFolderExists(path))
			print "Vectors are already present. Use the existing waves"
		else
			String/G wavename_pref=L_wavename_pref
			Variable/G Unit=L_unit
			Variable/G Layerstart=L_Layerstart
			Variable/G LayerEnd=L_LayerEnd
			variable/G button_bleachcorrect=L_button_bleachcorrect
			variable/G bleachrate
			variable/G OptimizationMethod=L_OptimizationMethod
			wave Original3Dwave=$V9_Original3Dwave()
			if (button_bleachcorrect!=0)		//041127 modified
			 	bleachrate=V9_calcBleachRate(Original3Dwave,Layerstart,LayerEnd)		//031203
			else
				bleachrate=0
			endif	
			NewDataFolder $path
			VectorFieldDerive()
			path=("root:"+Foldername+":")
//			if (button_bleachcorrect!=0)
			if (button_bleachcorrect!=0)		//041127
				MoveWave $(V9_Original3Dwave()+"_Blch") $path		//040122
				//MoveWave $(V9_Original3Dwave()+"_BlchD") $path		//040122
			endif
			MoveWave VX $path
			MoveWave VY $path
			MoveWave VX_error $path
			MoveWave VY_error $path
			MoveString wavename_pref $path
			MoveVariable Unit $path
			MoveVariable LayerStart $path
			MoveVariable LayerEnd $path
			MoveVariable button_bleachcorrect $path
			MoveVariable bleachrate $path
			MoveVariable OptimizationMethod $path			
		endif

		setdatafolder $path
//*********local data folder
		Variable/G averaging=L_averaging
		averagingCore(VX,VY)
		Variable/G scale=L_scale
		DrawVectorALLcore(VXav,VYav)
		
		
		NVAR/z isPosition
		if (NVAR_exists(isPosition)==0)
			HistStatParameterInit()
		endif		// 020129
		HistAnalCore() //parameter=1, isPosition=0, isFilterd=0 (not filtered)
		path=("root:"+Foldername)
	endif
//********analysis	

	//Variable/G gSpeed_Threshold=0
	//Variable/G Dest_X=0
	//Variable/G Dest_Y=0
	//HistStatParameterInit()		// 020129		//these lines moved to 4lines up 020314 
	//HistAnalCore(1,0,0) //parameter=1, isPosition=0, isFilterd=0 (not filtered)		
	DoWindow/F $L_windowname	
	setdatafolder root:

END

//***************************************

Macro DoAllVecFieldMacro(L_wavename_pref,L_LayerStart,L_LayerEnd)
	String	L_wavename_pref
	Variable	L_unit=3
	Variable	L_LayerStart//=0
	Variable	L_LayerEnd//=9
	Variable L_averaging=3
	Variable L_scale=25
	variable L_button_bleachcorrect=1//060410 TLO
	variable L_OptimizationMethod=1 //TLO
	DoalltoshowVectorField_Core(L_wavename_pref,L_unit,L_LayerStart,L_LayerEnd,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod)
END
//******************************************************************
Function MultipleVectorField()			//040121 modified
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
	Doprompt "Input Parameters::",L_wavename_pref,L_unit,L_LayerStart,FramesPerField,FieldNumber,L_averaging,L_scale,L_button_bleachcorrect,L_OptimizationMethod

	if (V_flag)
		Abort "Processing Canceled"
	endif

	//String	FolderName,windowname,WindowMatching
	String/G path			//string at the root directory
	Variable L_LayerEnd,layernumber,count

	Wave originalMatrix=$L_wavename_pref //matrix name
	layernumber=DimSize(originalMatrix, 2)
	
	L_wavename_pref=(L_wavename_pref[3,(strlen(L_wavename_pref)-1)])
	if (L_unit==1)
		L_unit=3
	elseif (L_unit==2)
		L_unit=2
	endif
	L_averaging =L_averaging*2+1	//correction for the popup menue
	L_button_bleachcorrect-=1	

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

//		FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
//		path=("root:"+Foldername)
////-------------------------------------------
//		if (DataFolderExists(path))
//			print (num2str(L_LayerStart)+"-"+num2str(L_LayerEnd)+" Vectors are already present. Use the existing waves")
//		else
//			String/G wavename_pref=L_wavename_pref
//			Variable/G Unit=L_unit
//			Variable/G Layerstart=L_Layerstart
//			Variable/G LayerEnd=L_LayerEnd
//			NewDataFolder $path
//			VectorFieldDerive()
//			path=("root:"+Foldername+":")
//			MoveWave VX $path
//			MoveWave VY $path
//			MoveString wavename_pref $path
//			MoveVariable Unit $path
//			MoveVariable LayerStart $path
//			MoveVariable LayerEnd $path
//		endif
//		
//		setdatafolder $path
//		Variable/G averaging=L_averaging
//
//		averagingCore(VX,VY)
//		Variable/G scale=L_scale
//		//Variable/G scale=L_scale
//
//		DrawVectorALLcore(VXav,VYav)
//		setdatafolder root:
//		path=("root:"+Foldername)
		
		L_Layerstart=(L_Layerstart+FramesPerField)
		count=count+1
	while (count<fieldnumber)
	
END

//****************************************************************************************************
// following two functions were copied from anal2.ipf

Function RemoveFilteredWaveTrace()		// 020336

	String traces=tracenamelist("",";",1)
	Variable filtered_trace_Index=WhichListitem("Ypoints_filtered",traces)
	//print traces
	if (filtered_trace_Index!=-1)
//	if (  waveexists(Ypoints_filtered)==0)
//		print "No Filtered Wave (Yellow Vectors) in this Graph"
//	else
		RemoveFromGraph Ypoints_filtered
	else
		print "No Filtered Wave (Yellow Vectors) in this Graph"
		print traces
	endif

END

//**************************************************************************
Function AddFilteredVec(L_VX_filteredav,L_VY_filteredav)
	wave L_VX_filteredav,L_VY_filteredav
	NVAR rnum,cnum
	//print nameofwave(L_VX_filteredav)
	//print nameofwave(L_VY_filteredav)
	rnum=DimSize(L_VX_filteredav, 0)
	cnum=DimSize(L_VX_filteredav, 1)
	Make/O/N=(3*rnum*cnum) Xpoints_filtered,Ypoints_filtered
	Make/O/N=(rnum*cnum) gridXpoints_temp, gridYpoints_temp
	Realign_2Dto1D(L_VX_filteredav,L_VY_filteredav,gridXpoints_temp,gridYpoints_temp,Xpoints_filtered,Ypoints_filtered)
	KillWaves gridXpoints_temp,gridYpoints_temp

	
	Dowindow/F $VectorFieldWindowName()
	
	if (WhichListItem("Ypoints_filtered", TraceNameList("", ";", 1 ))==(-1))
		//print TraceNameList("", ";", 1 )
		AppendToGraph Ypoints_filtered vs Xpoints_filtered
		ModifyGraph rgb(Ypoints_filtered)=(65280,65280,0)
		ModifyGraph lsize(Ypoints_filtered)=2
	endif
		
END

 