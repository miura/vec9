#pragma rtGlobals=1		// Use modern global access method.

#include "VEC9_core"
#include "VEC9_main"
#include "VEC9_ControlPanel"
#include "VEC9_anal"
//#include "VEC9_anal2"		//commented out 030729
#include "VEC9_NoiseRemove"
#include "VEC9_graphs"
//#include "VEC9_maskMeasurement"	//commented out 030729
#include "VEC9_2Dhist"
#include "VEC9_2Dhist_anal"
#include "Vec9_DataFolderIO"
//#include "VEC9_rangeSimple"		WM import
#include "VEC9_SimuAnal"
#include "VEC9_USRio"
#include "VEC9_wavesort"
#include "VEC9_equalize3D"
#include "Vec9_imageprocessing"
#include "VEC9_CustomMeasurements"
#include "Vec9_anal3"		//021211
#include "Vec9_vonMisesStat"
#include "Vec9_FlowSim"  //030516
#include "Vec9_Filters"  //030527
#include "VEC9_core02"	//031203
#include <image common>
//#include "VEC9_analNewtemp"

//#include "VEC9_VecRangeGraph"		WM import  

// "directionality" menue is in Vec9_anal3
// V9_Show_Roi_Center() : GraphMarquee in Vec9_USRio.ipf

//*********************************************************** 
Menu "VectorField"
	"Load TIFF sequence...(", LoadTIFFsequence()
	"Load TIFF Stack...", LoadTIFFstackV2()  //LoadTIFFstack()
	"Load Masking binary image...", LoadMASKTIFF()
//	"Rename TIFF stack files as Matrix", RenameTiffToMAT()
	"Save 3D matrix as TIFF sequence",V9_Save3Dmatrix_as_2Dbmpseq()
	"-"
	"Equalize 3D", V9_do3Dequalize()
	"-"
	"Single Vector Field", DoalltoshowVectorField()
	//"Sequence of Vector Fields (", MultipleVectorField()
	"-" 
	//"Vector Field Control Planel...",VectorFieldPanel()
	"Vector Field Control Bar...",VectorFieldBar() 
	"Remove Control Bar",V9_VectorFieldBarRemove()
	"-" 
//	Submenu "Vector Modification.."
//		"Change scaling", DrawNewScale()
//		"Change averaging", DrawNewAverage()
//	End
	"Create Filter Panel...",V9_CreateFilterPanel()
//	submenu "1D filtering"
//		"Show Vectors in a Range of Speed...", VecRangeGraphProc()
//		//"Show Vectors in a Range of Average Speed...", VecRangeByAVEProc()  --> this became "unused" in anal2.ipf
//	end
	submenu "2D histogram"
		"velocity vs angle", V9M_DoVeloAngl2DHist()
		"pixel intensity vs angle",V9M_DoIntAngl2DHist()
		"velocity vs pixel intensity",V9M_DoVeloInt2DHist()
//		"-"
//		"velocity&intensity filtering by user input...",V9_filter_2Dplot_parainput()
		"-"
		"View mask image",V9_viewMaskedImg()
		"Invert Mask",InvertBinMASK()
		//"Do Masked Grad Stat...",VEC_DoMaskedStat()		
//		"Mask Image ON",V9_setMaskImagefunc_switch(1); setdatafolder root:
//		"Mask Image OFF",V9_setMaskImagefunc_switch(0); setdataFolder root:
//		V9_Menu_MaskImageSwitch(), V9_Menu_toggleMaskImageSwitch()
		"-" 
		"Remove Filtered Vectors",RemoveFilteredWaveTrace()
		"-" 
		"set z-projection method",V9_setTProjectionMethod()				//new 020905
		"Clear ROI and Do Basic Stat", V9_histanal_DoBasic()
	end
	submenu "Noise Analysis"
//		"Full Frame", HistAnal()
//		"ROI statistics", ROI_statistics()
		//"Kill all the statistic waves", Killstatwaves()
//		"-"
//		"Initialize Panel Parameters", VectorFieldPanelInit()
//		"-" 
		"Load Noise Parameters",  LoadNoiseParameters()
		"Generate Noise histogram", DoGenerateNoiseHistogram()
		"Set Noise Method...", SetNoiseMethod()
		"-"
		"Show De-Noise-Filtered Speed Histogram", DisplayNoiseLessSpeed("ALL")
		"Show De-Noise-Filterd Speed Histogram ROI", DisplayNoiseLessSpeed("ROI")
	end
	"-" 	
	submenu "Graph Utilities"
		"Set Speed HIst Bin Width...", GetBinWidth()
		"Rotate the Trace Order", BringTheFrontTraceBottom()
		"-"
		"Bring up the Stats Forward", BringtheStatsForward()
		"Kill Related Windows",KillRelatedWindows()
		"Kill ROI stat Windows", KillRoiStatWindows()
		"-"
		"print parameters", PrintFilterParameters()
	end
	submenu "Flow Analysis"
		"Calculate Flow",V_FlowHist()
		"Set background Intensity...",GetBackgroundInt()
		"Set Speed Factor...",GetSpeedFactor()
		"Set Work bin width...",GetBinWidthFlow()
		"-"
		"Show Crude Flow Direction",VEC9_TriDirectionForce_Histo() 
	end	
	submenu "Flow Simulation"
		"Simulate Flow",V9_MenuIterateFlow() 
	end

	"-"	
	submenu "ROI Measurement"
		"Show ROI",V_ShowCurrentROI()
		"Clear ROI drawing",V_Cleardrawings()	
		"-"
		"ROI Measure Rec -> ON",RoiStatMeasureFlag_ON()
		"ROI Measure Rec -> OFF",RoiStatMeasureFlag_OFF()
		"-"
		"Name the ROI stat wave...",Name_ROIstat()
		"Make the ROI stat waves",Make_ROIstat_toWave()
		"Show ROI stat wave table",Edit_RoiStatWaves()
	end

//	"-" 
	"Save the Graph...eps",SavePICT/E=-3
	"Save the Graph...jpg",SavePICT/T="JPEG"/B=144
end

//************************************************************

//Function/s V9_Menu_MaskImageSwitch()
//	if (cmpstr(WinName(0,1), "")!=0)
//		String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
//	endif
//	String ImageMaskState="Mask Image ON"
//	if (DataFolderExists("Analysis"))
//		NVAR ImageMask_ON=:analysis:ImageMask_ON
//		if (ImageMask_ON==1)
//			ImageMaskState="Mask Image OFF"
//		else
//			ImageMaskState="Mask Image ON"
//		endif
//	endif
//	BuildMenu "VectorField"
//	setdatafolder root:
//	return ImageMaskState
//END

//Function V9_Menu_toggleMaskImageSwitch()
//		String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
//		NVAR ImageMask_ON=:analysis:ImageMask_ON
//		ImageMask_ON=( ImageMask_ON==1 ? 0 : 1)
//		setdatafolder root:
//END