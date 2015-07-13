#pragma rtGlobals=1		// Use modern global access method.


//preparing substraction image
function/S V9_subtractionImage(src3Dwave,substep)
	wave src3Dwave
	variable substep
	string src3Dwavename=nameofwave(src3Dwave)
	string sub3Dwavename=nameofwave(src3Dwave)+"_sub"+num2str(substep)
	Make/O/N=(DimSize(src4Dwave,0),DimSize(src4Dwave,1),DimSize(src4Dwave,2)) $sub3Dwavename
	wave sub3Dwave=$sub3Dwavename
	sub3Dwave[][][]=src3Dwave[p][q][r+substep]-src3Dwave[p][q][r]
	return sub3Dwavename
END