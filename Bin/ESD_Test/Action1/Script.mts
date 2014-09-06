 @@ hightlight id_;_65776_;_script infofile_;_ZIP::ssf329.xml_;_

Option Explicit
Dim rc, i, strTestSetName, arrTestSet, strReportFile, iElapsedTime

'Set up environment for TestSet
Preset_TestSet

'  Kill Excel process
OS_KillBrowsers @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment").WebButton("Add DocType")_;_script infofile_;_ZIP::ssf336.xml_;_

'OS_KillProcess LOCAL_HOST_NAME, EXCEL_PROCESS_NAME 

'Indentify application path
WEB_URL = "http://192.168.1.201:3000/"

Datatable.AddSheet("TestCase")
Datatable.ImportSheet TESTCASE_FOLDER & TESTCASE_SOURCE, "TestCase", "TestCase" 
' Load Testset
arrTestSet = Split(TESTSET_ARRAY, ";")
Datatable.AddSheet("TestSet")
For i = 0 To Ubound(arrTestSet)	
	' Load Testset
	strTestSetName = Trim(arrTestSet(i))
	If Right(strTestSetName, 4) <> ".xls" Then
		strTestSetName = strTestSetName & ".xls"
	End If
	Datatable.ImportSheet TESTSET_FOLDER & strTestSetName, "TestSet", "TestSet" 
	' Run Testset	
	Dim StartTime: StartTime = Now()	
	LogMessage(vbCrLf & "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
	LogMessage("Test Set: " & strTestSetName)
	RunTestSet()
	LogMessage(" ")
	LogMessage("Complete Test Set: " & strTestSetName)
	LogMessage(" ")
	Dim EndTime: EndTime = Now()
	' Update Testset Result	
	UpdateTestSetResult(strTestSetName)	
	' Export Result	
	iElapsedTime = TimeSpan(StartTime, EndTime) 
	strReportFile = GenerateTestReport(strTestSetName, iElapsedTime)  	
	Print vbCrLf
	Print "Total TCs" & vbTab & ": " & Environment.Value("ITOTAL") 
	Print "   . Passed" & vbTab & ": " & Environment.Value("IPASSED") 
	Print "   . Failed" & vbTab & ": " & Environment.Value("IFAILED") 
	Print "   . Blocked" & vbTab & ": " & Environment.Value("IBLOCKED") 
	Print "   . No Run" & vbTab & ": " & Environment.Value("INORUN")
	' Send Result email
	If REPORT_SEND_EMAIL Then
		SendTestSetResultEmail strTestSetName, strReportFile
	End If
	' Upload Test result to ALM
	If UPLOAD_RESULT Then	
		UploadTestSetResult strTestSetName
	End If       	
Next

