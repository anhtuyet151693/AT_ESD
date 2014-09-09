 @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment 2").WebList("select")_;_script infofile_;_ZIP::ssf346.xml_;_
 @@ hightlight id_;_65782_;_script infofile_;_ZIP::ssf343.xml_;_
Option Explicit
Dim rc, i, strTestSetName, arrTestSet, strReportFile, iElapsedTime

Preset_TestSet

WEB_URL = "http://tfs.innoria.com:3000/"

'
'Browser("eSkyDesk Management").Page("eSkyDesk Management").WebButton("Login").Click 140,20 @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkyDesk Management").WebButton("Login")_;_script infofile_;_ZIP::ssf357.xml_;_
'Browser("eSkyDesk Management").Page("eSkyDesk Management").Sync @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkyDesk Management")_;_script infofile_;_ZIP::ssf358.xml_;_
'Browser("eSkyDesk Management").Navigate "http://tfs.innoria.com:3000/Authentication/Login"
'Browser("eSkyDesk Management").Page("eSkydesk Managment").Sync @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment")_;_script infofile_;_ZIP::ssf359.xml_;_
'Browser("eSkyDesk Management").Back
'Browser("eSkyDesk Management").Page("eSkydesk Managment").WebEdit("UserName").Set "adminvdfvdfgfdg" @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment").WebEdit("UserName")_;_script infofile_;_ZIP::ssf360.xml_;_
'Browser("eSkyDesk Management").Page("eSkydesk Managment").WebButton("Login").Click 163,13 @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment").WebButton("Login")_;_script infofile_;_ZIP::ssf361.xml_;_
'Browser("eSkyDesk Management").Page("eSkydesk Managment").Sync @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkydesk Managment")_;_script infofile_;_ZIP::ssf362.xml_;_
'Browser("eSkyDesk Management").Navigate "http://tfs.innoria.com:3000/Authentication/Login"
'Browser("eSkyDesk Management").Page("eSkyDesk Management_2").Sync @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkyDesk Management_2")_;_script infofile_;_ZIP::ssf363.xml_;_
'Window("Window").Click 684,175 @@ hightlight id_;_65798_;_script infofile_;_ZIP::ssf364.xml_;_
'Window("Window").Click 689,148 @@ hightlight id_;_65798_;_script infofile_;_ZIP::ssf365.xml_;_
'Browser("eSkyDesk Management").Page("eSkyDesk Management_2").Check CheckPoint("eSkyDesk Management") @@ hightlight id_;_Browser("eSkyDesk Management").Page("eSkyDesk Management_2")_;_script infofile_;_ZIP::ssf366.xml_;_



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

