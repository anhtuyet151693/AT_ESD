'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
' Script Name: FrameworkFunctions.vbs
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
'Option Explicit

Const TEST_LOG_MODE = 8 ' 8: Appending; 2: Overwrite

Dim SPECIAL_TEST_CASE_LIST_FILE 
Dim LOCAL_HOST_NAME
Dim REPORT_FOLDER
Dim TESTSET_FOLDER
Dim TESTCASE_FOLDER
Dim RESOURCE_FOLDER
Dim DATATABLE_FOLDER
Dim ADDINS_FOLDER
Dim REGISTRY_FOLDER
Dim SQLINPUT_FOLDER
Dim SCREENSHOT_FOLDER
Dim CONFIGURATION_FOLDER
Dim LOG_FOLDER
Dim TEST_LOG_FILE
Dim REPORT_NAME 
Dim objExcel, objWorkbook, objWorksheet, objRange
Dim LineStyle
Dim Weight
Dim ColorIndex
Dim ROOT_FOLDER
Dim WEB_URL


ROOT_FOLDER = Environment.Value("TestDir") & "\..\..\"
REPORT_FOLDER = ROOT_FOLDER & "TestReport\" 
TESTSET_FOLDER = ROOT_FOLDER & "TestSet\"
TESTCASE_FOLDER = ROOT_FOLDER & "TestCase\"
RESOURCE_FOLDER = ROOT_FOLDER & "Resource\"
LOG_FOLDER = ROOT_FOLDER & "Log\"
SCREENSHOT_FOLDER = ROOT_FOLDER & "Screenshot\"
DATATABLE_FOLDER = RESOURCE_FOLDER & "Datatable\"
ADDINS_FOLDER = RESOURCE_FOLDER & "Addins\"
REGISTRY_FOLDER = RESOURCE_FOLDER & "Registry\"
SQLINPUT_FOLDER = RESOURCE_FOLDER & "SQLInputFile\"
CONFIGURATION_FOLDER = RESOURCE_FOLDER & "Configuration\"
'REPORT_NAME = "REPORT_" & BUILD_VERSION & ".xls"
LOCAL_HOST_NAME = Environment.Value("LocalHostName")
Environment.Value("Error_Message") = ""
Environment.Value("Clipboard") = ""
Environment.Value("IsTCFailed") = ""
TEST_LOG_FILE = TimeStamp() & ".txt"
SPECIAL_TEST_CASE_LIST_FILE = RESOURCE_FOLDER & "Configuration\SpecialTestCases.txt"

'Auto-create Folders
If OS_CheckFolderExists(REPORT_FOLDER)= 0 Then OS_CreateFolderByPath(REPORT_FOLDER)
If OS_CheckFolderExists(LOG_FOLDER)= 0 Then OS_CreateFolderByPath(LOG_FOLDER)
If OS_CheckFolderExists(SCREENSHOT_FOLDER) = 0 Then OS_CreateFolderByPath(SCREENSHOT_FOLDER)
if OS_CheckFolderExists("C:\Temp") = 0 Then OS_CreateFolderByPath("C:\Temp")

'Load Environment Variables
If OS_CheckFileExists(CONFIGURATION_FOLDER & LOCAL_HOST_NAME & ".txt") Then
   ExecuteFile CONFIGURATION_FOLDER & LOCAL_HOST_NAME & ".txt"
Else

	ExecuteFile CONFIGURATION_FOLDER & "Default.txt"
'ExecuteFile "C:\QTPF\Resource\Configuration\Default.txt"
End If

REPORT_NAME = "REPORT_" & BUILD_VERSION & ".xls"


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Class Name: Quality_Center
' Description: 
' Parameter: 
' History: 
'	- 2011-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Class Quality_Center
	Public QCUrl
	Public QCDomain
	Public QCProject
	Public QCUser
	Public QCPassword
	Public TestSetFolder 
	Public TestSet 
	Public TestCase 
	Public TestCaseStatus 			
	Public UploadFilePath 
	Public TestSetResultFile
	Public TestServerName
	Public BuildVersion
	Public RunComment
	Private DefaultTestRunInstance
	Private QCConnect
	Private qtApp
	Private TestSetFact
	Private TestSetTree

	Sub Class_Initialize()
		DefaultTestRunInstance = "[1]"	
		QCUrl = QC_URL
		QCDomain = QC_DOMAIN
		QCProject = QC_PROJECT
		QCUser = QC_USER
		QCPassword = QC_PASSWORD
		BuildVersion = BUILD_VERSION
		TestServerName = Environment.Value("LocalHostName")
		TestSetFolder = TEST_LAB_FOLDER	
	End Sub	

	' QC Connect Setup
	Function ConnectToQC()
		Set qtApp = CreateObject("QuickTest.Application")
		qtApp.TDConnection.Connect QCUrl, QCDomain, QCProject, QCUser, QCPassword, True		
		If qtApp.TDConnection.IsConnected = False Then
			wscript.echo "Failed to connect to QC"
			ConnectToQC = 1
			Exit Function
		End If
		Set QCConnect = qtApp.TDConnection.TDOTA
		ConnectToQC = 0
	End Function	
    	
	' Upload TC Result to QC
	Function UploadTCResultToQCTestLab(strTestSetName)
		Dim oRun
		Dim objTestFolder
		Dim TSList, theTestSet, TestInstanceFactory, TSTestList
		Dim i, theRunTest, UploadResult, RunFact, RunName
		Dim strUploadFileName, strUploadFileFolder

		' Find Test Set and Test Case on the QC Test Lab	
		Set TestSetFact = QCConnect.TestSetFactory	
		Set TestSetTree = QCConnect.TestSetTreeManager			
		Set objTestFolder = TestSetTree.NodeByPath(TestSetFolder)	
		TestSet = Replace(strTestSetName, ".xls", "")
		Set TSList = objTestFolder.FindTestSets(TestSet)	
		On Error Resume Next
		Set theTestSet = TSList.Item(1)
		On Error Goto 0

		Set TestInstanceFactory = theTestSet.TSTestFactory
		Set TSTestList = TestInstanceFactory.NewList("")	
		
		Dim iFound: iFound = False
		For i = 1 to TSTestList.Count
			If TSTestList(i).Name = DefaultTestRunInstance & TestCase Then
				Set theRunTest = TSTestList(i)
				iFound = True
				Exit For
			End If
		Next	
		
		'If theRunTest Is Nothing Then
		If iFound = False Then
			Reporter.ReportEvent micFail, "UploadQCResult", "Failed to find: " & _
				TestRunInstance & TestCase & " on QC"
			UploadResult = False
			Exit Function
		End If
		
		Set RunFact = theRunTest.RunFactory	

		' Create a new Test Run
		If BUILD_VERSION <> "" Then
			RunName = TestCase & "_" & BUILD_VERSION
		Else		
			RunName = TestCase & "_" & TimeStamp()
		End If
			
		Set oRun = RunFact.AddItem(CStr(RunName))

		' Post Test Case Status
		oRun.Status = TestCaseStatus
		oRun.Field("RN_USER_03") = BuildVersion
		oRun.Field("RN_USER_02") = Left(RunComment, 40)
		oRun.Field("RN_HOST") = TestServerName
		oRun.Post
		oRun.Refresh
		
		'Set oAtt = Nothing
		'Set oStorage = Nothing
		'Set oAttFact = Nothing
		Set oRun = Nothing
		Set RunFact = Nothing		
		Set TSTestList = Nothing
		Set TestInstanceFactory = Nothing
		Set theTestSet = Nothing
		Set TSList = Nothing
		Set theRunTest = Nothing
		
	End Function
	
	' Disconnect QC
	Function DisconnectQC()
		qtApp.TDConnection.Disconnect	
		Set QCConnect = Nothing	
		Set qtApp = Nothing
	End Function
	
End Class


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: UpdateTCResultOnQC
' Description:
' Parameter:
' History:
'	- 2011-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function UpdateTCResultOnQC(strTestSetName, strTCName, strTCResult, strRunComment)
	Dim oQC
	Set oQC = New Quality_Center
	If UPLOAD_RESULT Then   		
		LogMessage("Upload result of the test case '" & strTCName & "' to ALM...")
		oQC.ConnectToQC()
		oQC.TestCase = strTCName
		oQC.TestCaseStatus = strTCResult
		oQC.RunComment = strRunComment
		oQC.UploadTCResultToQCTestLab(strTestSetName)
		oQC.DisconnectQC()
		LogMessage("Upload result of the test case '" & strTCName & "' to ALM --> Done")
	End If	
	Set oQC = Nothing
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: UploadTestSetResult
' Description:
' Parameter:
' History: 
'	- 2012-05-04 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function UploadTestSetResult(strTestSetName)
	Dim i, oQC
	Replace strTestSetName, ".xls", ""
	'LogMessage("Upload result of test set '" & strTestSetName & "' to ALM...")
	Set oQC = New Quality_Center
	oQC.ConnectToQC()
	For i = 1 To Datatable.GetSheet("TestSet").GetRowCount
		Datatable.GetSheet("TestSet").SetCurrentRow(i)	
		If Ucase(Datatable.Value("Testable", "TestSet")) = "End" Then
			Exit Function
		End If
		If Ucase(Datatable.Value("Testable", "TestSet")) = "Y" Then		
			oQC.TestCaseStatus = Datatable.Value("Result", "TestSet")
			If (oQC.TestCaseStatus = "Failed") Or (oQC.TestCaseStatus = "Passed") Then
				oQC.TestCase = Datatable.Value("TestCase", "TestSet")
         	oQC.RunComment = Datatable.Value("RunComment", "TestSet")
				oQC.UploadTCResultToQCTestLab(strTestSetName)
				LogMessage("Upload result of test case '" & oQC.TestCase & "' to ALM --> Done")
			End If
		End If
	Next
	oQC.DisconnectQC()
	'LogMessage("Upload result of test set '" & strTestSetName & "' to ALM --> Done")
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Class Name: eMail
' Description:
' Parameter:
' History: 
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Class eMail
	Public Method
	Public Server
	Public Port
	Public Sender
	Public Recipients
	Public Subject
	Public Content
	Public TestSetName
	Public HostName
	Public AttachedFilePath
	
	Sub Class_Initialize()
		Subject    = ""
		Content    = ""
		Method     = 2
		Server     = EMAIL_SERVER
		Port       = EMAIL_PORT
		Sender     = EMAIL_SENDER
		Recipients = EMAIL_REPCIPIENT			
	End Sub	

	'
	' Send Mail 
	'
	
	Function SendMail()
		Dim mail
		LogMessage("Send test result email...")
		Set mail = CreateObject("CDO.Message")
		mail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = Method
		mail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = Server
		mail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = Port
		mail.Configuration.Fields.Update
		mail.From = Sender
		mail.To = Recipients
		mail.Subject = Subject
		mail.TextBody = Content
		If AttachedFilePath <> "" Then
			mail.AddAttachment AttachedFilePath		
		End If
		mail.Send	
		LogMessage("Send test result email --> Done")	
	End Function
End Class	


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: SendTestSetResultEmail
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function SendTestSetResultEmail(strTestSetName, strReportFile)
	Dim oEmail, strEvn
	strEvn = " (" + WINDOWS_VERSION + " - " + MS_OFFICE_VERSION + ")"
	Set oEmail = New eMail
	oEmail.Server = REPORT_EMAIL_SERVER
	oEmail.Port = REPORT_EMAIL_PORT
	oEmail.Sender = REPORT_EMAIL_SENDER
	oEmail.Recipients = REPORT_EMAIL_REPCIPIENT        	
	If CInt(Environment.Value("IFAILED")) = 0 Then
		oEmail.Subject = BUILD_VERSION + " - Passed " + _
		CStr(Environment.Value("IPASSED")) & "/" & CStr(Environment.Value("ITOTAL")) & " automated test cases" 
	Else
		oEmail.Subject = BUILD_VERSION + " - Failed " + _
		CStr(Environment.Value("IFAILED")) & "/" & CStr(Environment.Value("ITOTAL")) & " automated test cases" 
	End If	
	oEmail.Subject = oEmail.Subject & strEvn
	oEmail.Content = "::: Automation Test Report :::" + vbCrLf + vbCrLf + _
	"Build" + vbTab + vbTab + ": " + BUILD_VERSION + vbCrLf + _
	"Test server" + vbTab + ": " + LOCAL_HOST_NAME + strEvn + vbCrLf + _
	"Test cases" + vbTab + ": " + CStr(Environment.Value("ITOTAL")) + vbCrLf + _
	"   . Pass" + vbTab + ": " + CStr(Environment.Value("IPASSED")) + vbCrLf + _
	"   . Failed" + vbTab + ": " + CStr(Environment.Value("IFAILED")) + vbCrLf + _
	"   . Blocked" + vbTab + ": " + CStr(Environment.Value("IBLOCKED")) + vbCrLf + _
	"   . Not Run" + vbTab + ": " + CStr(Environment.Value("INORUN")) + vbCrLf + vbCrLf + _
	"Please see attached file for detail..." 
	oEmail.TestSetName = strTestSetName
	oEmail.AttachedFilePath = REPORT_FOLDER & strReportFile	
	oEmail.SendMail()				
	Set oEmail = Nothing	
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: TimeSpan
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function TimeSpan(StartTime, EndTime) 
	Dim seconds, minutes, hours 
	If (isDate(StartTime) And IsDate(EndTime)) = false Then 
		TimeSpan = "00:00:00" 
		Exit Function 
	End If 
	seconds = Abs(DateDiff("S", StartTime, EndTime)) 
	minutes = seconds \ 60 
	hours = minutes \ 60 
	minutes = minutes mod 60 
	seconds = seconds mod 60 
	if len(hours) = 1 then hours = "0" & hours 

	TimeSpan = hours & ":" & _ 
		RIGHT("00" & minutes, 2) & ":" & _ 
		RIGHT("00" & seconds, 2) 
End Function 


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: UpdateTestSetResult
' Description:
' Parameter: 
' History: 
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function UpdateTestSetResult(strTestSetName)
	Dim i, j, iFound
	LogMessage("Update result of test set '" & strTestSetName & "'...")
	For i = 1 To Datatable.GetSheet("TestSet").GetRowCount
		Datatable.GetSheet("TestSet").SetCurrentRow(i)
		If Ucase(Datatable.Value("Testable", "TestSet")) = "End" Then
			Exit Function
		End If
		If Ucase(Datatable.Value("Testable", "TestSet")) = "Y" Then
			iFound = 0
			For j = 1 To Datatable.GetSheet("TestCase").GetRowCount
				Datatable.GetSheet("TestCase").SetCurrentRow(j)
				If Datatable.Value("Result", "TestCase") = "End" Then
					Exit For
				End If
				If (Ucase(Datatable.Value("TCID", "TestCase")) = Ucase(Datatable.Value("TCID", "TestSet"))) Then
					If Ucase(Datatable.Value("Result", "TestCase")) = "NO RUN" Then
						iFound = 1
					End If
					If Ucase(Datatable.Value("Result", "TestCase")) = "PASSED" Then
						Datatable.Value("Result", "TestSet") = "Passed"
					End If
					If UCase(Datatable.Value("Result", "TestCase")) = "FAILED" Then
						Datatable.Value("Result", "TestSet") = "Failed"
						Exit For
					End If
				End If
			Next
			If Datatable.Value("Result", "TestSet") = "No Run" Then
				If iFound = 0 Then
					If Datatable.Value("Result", "TestSet") <> "Failed" Then
						Datatable.Value("RunComment", "TestSet") = "Test case not found"
					End If
				Else
					Datatable.Value("Result", "TestSet") = "Blocked"
				End If
			End If
		End If
	Next
	LogMessage("Update result of test set '" & strTestSetName & "' --> Done")
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: ReportAction
' Description:
' Parameter:
' History:
'	- 2010-10-10-20: Initial Revision
'	- 2010-10-12-29: Update to print result and select cases : Dung Nguyen
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Sub ReportAction(iResult, strStepName, strDetail)	
	Dim strLogMessage
	Select Case iResult
		Case 0 ' Done
			Reporter.ReportEvent micDone, strStepName, strDetail			
		Case 1 ' Passed
			Reporter.ReportEvent micPass, strStepName, strDetail			
		Case Else 'Failed
			TakeScreenShot strStepName & "(" & strDetail & ")"
			Reporter.ReportEvent micFail, strStepName, strDetail  
			Environment.Value("IsTCFailed") = "OK"      					
	End Select
	Environment.Value("Error_Message") = iResult & " | " & strStepName & "  --> " & strDetail 	
	strLogMessage = Time & vbTab & "| " &  iResult & vbTab & "| " & strStepName & "  --> " & strDetail
	LogMessage(strLogMessage)
End Sub


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: LogMessage
' Description:
' Parameter:
' History:
'	- 2010-10-10-20: Initial Revision			
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function LogMessage(strLogMessage)
	Dim fso, f, strFileName		
	Set fso = CreateObject("Scripting.FileSystemObject")   	
	Set f = fso.OpenTextFile(LOG_FOLDER & TEST_LOG_FILE, TEST_LOG_MODE, True)   
	f.WriteLine strLogMessage
	f.Close
	Set f = Nothing
	Set fso = Nothing
	Print strLogMessage
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: RunSpecialTestCase
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function RunSpecialTestCase(strTCName)
	If SPECIAL_TESTCASE_SUPPORT <> True Then
		Exit Function
	End If
	If IsSpecialTestCase(strTCName) Then 
		Datatable.ImportSheet DATATABLE_FOLDER & strTCName & ".xls", "Global", "Global"
		LoadAndRunAction TESTCASE_FOLDER & strTCName, strTCName 
		Datatable.ImportSheet DATATABLE_FOLDER & "ClearGlobalSheet.xls", "Global", "Global"    						
		Datatable.Value("RunComment", "TestSet") = "Get Rerport at " & reporter.ReportPath & "\Log\LogFile.html"
		Datatable.Value("Result", "TestSet") = "Done"
		RunSpecialTestCase = True
	Else
		RunSpecialTestCase = False
	End If
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: IsSpecialTestCase
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function IsSpecialTestCase(strTCName)
	Dim FSO, oFile, strLine
	Dim iFound : iFound = False
   If SPECIAL_TESTCASE_SUPPORT <> True Then
		IsSpecialTestCase = False
		Exit Function
	End If
	Set FSO = CreateObject("Scripting.FileSystemObject")	
	Set oFile = FSO.OpenTextFile(SPECIAL_TEST_CASE_LIST_FILE,1)
	Do While oFile.AtEndOfStream <> True
		strLine = oFile.ReadLine()
		If InStr(strLine, strTCName) > 0 Then
			iFound = True
			Exit Do
		End If
	Loop
	Set oFile = Nothing
	Set FSO = Nothing	
	IsSpecialTestCase = iFound
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: GetTCStatus
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function GetTCStatus(strTCID)	
	Dim i
	Dim iFailed : iFailed = 0
	Dim strResult
	Datatable.ExportSheet "C:\Temp\Sheet.xls", "TestCase"
	Datatable.AddSheet("Temp")
	Datatable.ImportSheet "C:\Temp\Sheet.xls", "TestCase", "Temp"
	For i = 1 To Datatable.GetSheet("Temp").GetRowCount
		Datatable.GetSheet("Temp").SetCurrentRow(i)
		If UCase(Datatable.Value("TCID", "Temp")) = UCase(strTCID) Then
			strResult = Datatable.Value("Result", "Temp")
			Select Case strResult
				Case "Passed"
					iPass = 1
				Case "Failed"
					GetTCStatus = "Failed"
					Datatable.DeleteSheet("Temp")
					Exit Function	
				Case "Blocked"
					GetTCStatus = "Blocked"
					Datatable.DeleteSheet("Temp")
					Exit Function	
			End Select
			If iPass <> 0 Then
				GetTCStatus = "Passed"
			Else
				GetTCStatus = "No Run"
			End If
		End If
	Next
	Datatable.DeleteSheet("Temp")
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: RunTestSet
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function RunTestSet()	
	Dim i
	LogMessage(" ")		
	For i = 1 To Datatable.GetSheet("TestSet").GetRowCount 
		Datatable.GetSheet("TestSet").SetCurrentRow(i)   
'		MsgBox Datatable.Value("Testable", "TestSet")
		If Datatable.Value("Testable", "TestSet") = "End" Then		
			Exit Function
		End If
		If Datatable.Value("Testable", "TestSet") <> "" Then
			RunTestCase() 
		End If				
	Next	
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: RunTestCase
' Description:
' Parameter:
' History:
'	- 2010-10-10-20 | Initial Revision
'	- 2013-07-02-20 | Add execution time to TestSet report - NamDH7
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function RunTestCase()
	Dim rc, i, j 
	Dim intCount, iTSCount, iFound, iTCBypass, strAction, iParam, iResult, strCurrentTC, strPredecessors
	Dim iNOP
	' CheckPredecessors
	iTCBypass = 0  	
	If PREDECESSORS_MODE Then			
		strPredecessors = Datatable.Value("Predecessors", "TestSet")
		If strPredecessors <> "" And UCase(Datatable.Value("Testable", "TestSet")) = "Y" Then
			arrPredecessors = Split(strPredecessors, PREDECESSOR_DELIMITER)
			For k = 0 To Ubound(arrPredecessors)
				strCheckItem = Trim(arrPredecessors(k))
				strTCStatus = GetTCStatus(strCheckItem)
				If strTCStatus = "Failed" Or strTCStatus = "No Run" Or strTCStatus = "" Then
					iTCBypass = 1
					Exit For
				End If  			
			Next
		End If            	
	End If
	' Run Test		
	If Trim(UCase(Datatable.Value("Testable", "TestSet"))) = "Y" and (iTCBypass = 0) Then
		Dim StartTime: StartTime = Now()
		strCurrentTC = Datatable.Value("TCID", "TestSet")
		LogMessage(vbCrLf & "Test Case: " & strCurrentTC	& " - " & Datatable.Value("TestCase", "TestSet"))
		Dim WshShell
		Set WshShell = CreateObject("WScript.Shell")
		WshShell.Popup "Start To Run Test Case : " & strCurrentTC & " - " & Datatable.Value("TestCase", "TestSet") & "", 3
		Set WshShell = Nothing
		iResult = 3			
		iFound = 0
		For j = 1 To Datatable.GetSheet("TestCase").GetRowCount
			Datatable.GetSheet("TestCase").SetCurrentRow(j)	
			If Datatable.Value("Result", "TestCase") = "End" Then
				If iFound = 0 Then
					LogMessage("Test case not found. Please check Test case sheet !")
				End If
				Exit For
			End If
			If (Datatable.Value("TCID", "TestCase") = strCurrentTC) Then
				iFound = 1
				iTSCount = iTSCount + 1
				strAction = Datatable.Value("Action", "TestCase")		
				' Build Action 	
				strAction = strAction & "("					
				iNOP = CInt(Datatable.Value("NOP", "TestCase"))
				If iNOP = 0 Then
					strAction = strAction & ")"
				Else
					strParam = ConvertParam(Datatable.Value("Param1", "TestCase"))
					strAction = strAction & """" & strParam & """"
					For ip = 2 To iNOP
						strParam = ConvertParam(Datatable.Value("Param" & ip, "TestCase"))
						strAction = strAction & ", " & """" & strParam & """"
					Next
					strAction = strAction & ")"
				End If
				LogMessage("" & Time() & vbTab & "| Run " & vbTab & "| " & strAction & "")
				iResult = Eval(strAction)
				If Window("regexpwndtitle:=QuickTest Print Log").Exist(1) Then
					Window("regexpwndtitle:=QuickTest Print Log").Maximize
					Window("regexpwndtitle:=QuickTest Print Log").Activate
					Wait 1
					Datatable.Export(LOG_FOLDER & TESTCASE_SOURCE)
				End If
				'intCount = intCount + 1						
				If (iResult <> 1) And (iResult <> "") And (iResult <> 0) Then
					Datatable.Value("Result", "TestCase") = "Failed"
					Datatable.Value("Comment", "TestCase") = Environment.Value("Error_Message")
					Datatable.Value("RunComment", "TestSet") = Environment.Value("Error_Message")
					Environment.Value("Error_Message") = ""
					Exit For
				ElseIf IsEmpty(iResult) Then
					'Datatable.Value("Result", "TestSet") = "No Run"    
					iResult = "Null"
				Else
					Datatable.Value("Result", "TestCase") = "Passed"
				End If
				
				LogMessage("" & Time() & vbTab & "| " & iResult & vbTab & "| " & strAction & "")
			End If	
		Next
		
		Dim EndTime: EndTime = Now()
		Datatable.Value("Duration", "TestSet") = TimeSpan(StartTime, EndTime)
	End If	
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: ExportPrintLog
' Description: Export QuickTest Print Log to a flat file
' Parameter:
'	- strFilePath: File path
'  	- intExportMode: 2: New log file; 8: Appending log file
' History:
'	- 2010-10-12-30 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function ExportPrintLog()
	Dim FSO, oFile, rc
	' Create log file
	Set FSO = CreateObject("Scripting.FileSystemObject")
	Set oFile = FSO.OpenTextFile(LOG_FOLDER & OS_GenerateRandomData & ".txt", TEST_LOG_MODE, True)
	If Not Window("regexpwndtitle:=QuickTest Print Log").WinEditor("nativeclass:=Edit").Exist(2) Then
		oFile.Close
		Set oFile = Nothing
		Set FSO = Nothing
		Exit Function
	End If
	' Write print log content
	strContent = Window("regexpwndtitle:=QuickTest Print Log").WinEditor("nativeclass:=Edit").GetROProperty ("text")
	oFile.WriteLine(Now)
	oFile.WriteLine(strContent)
	oFile.WriteBlankLines(1)
    oFile.WriteLine("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	oFile.Close
	Set oFile = Nothing
	Set FSO = Nothing
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: LoadData
' Description:
' Parameter:
' History:
'	- 2012-01-06 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function LoadData(strDataFileName)
   If Right(strDataFileName, 4) <> ".txt"  Then
	   strDataFileName = strDataFileName & ".txt"
   End If
	ExecuteFile DATATABLE_FOLDER & strDataFileName
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: MinimizeQTPWindow
' Description:
' Parameter:
' History:
'	- 2012-02-13 | Initial Revision
'	- 2012-05-25 | Add minimizing Log window
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=
Function MinimizeQTPWindow()
    Dim qtApp
'	Window("regexpwndtitle:=QuickTest Print Log").Minimize
    Set qtApp = GetObject("","QuickTest.Application")
    qtApp.WindowState = "Minimized"
    Set qtApp = Nothing
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: RestoreQTPWindow
' Description:
' Parameter:
' History: 2012-02-13 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function RestoreQTPWindow()
	Dim qtApp
    Set qtApp = GetObject("","QuickTest.Application")
    qtApp.WindowState = "Normal"
    Set qtApp = Nothing
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: TakeScreenShot
' Description: Take a screen shot for report during test execution
' Parameter:
' History:
'	- 2012-02-13 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function TakeScreenShot(strScreenShotName)
	Dim strFolderPath, strFilePath, arr, i
    strScreenShotName = Replace(strScreenShotName, "\", "_")
    'replace invalid char to print out
    strScreenShotName = Replace(strScreenShotName, ":", "")
	strFolderPath = SCREENSHOT_FOLDER & Replace(Date, "/", "") & "\"
	arr = Split(strFolderPath, "\")
	strPath = arr(0)
	For i = 1 To Ubound(arr)
		strPath = strPath & "\" & arr(i)
		OS_CreateAFolder strPath
	Next
	'arr = Split(strScreenShotName, ".")
	Dim strPrefix
	strPrefix = Replace(Replace(Replace(Now, "/","."),":",".")," ","_")
	
	strFilePath = strFolderPath & strPrefix & "_" & strScreenShotName & ".png"
	MinimizeQTPWindow()
	Wait 1
	Desktop.CaptureBitmap strFilePath, True
	RestoreQTPWindow()
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: CloseChildDialogs
' Description: Close all child dialogs
' Parameter:
'	- oCurrentObject: Parent Object that has child objects needed to be closed
' History:
'	- 2012-02-13 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function CloseChildDialogs(oCurrentObject)
	Dim i
	If Not oCurrentObject.Exist(2) Then
		Exit Function
	End If
	Set oDescription = Description.Create()
	oDescription("Class Name").Value = "Dialog"
	Set oChild = oCurrentObject.ChildObjects(oDescription)
	If oChild.Count > 0 Then
		For i = 0 To oChild.Count - 1
			CloseChildDialogs oChild(i)
		Next
	End If
	If oCurrentObject.GetROProperty("Class Name") <> "Window" Then
		oCurrentObject.Close
		Wait 1
	End If
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: CreateEnvironmentVariable
' Description:
' Parameter:
'	- strVarName
'	- varValue
' History:
'	- 2012-02-13 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function CreateEnvironmentVariable(strVarName, varValue)
	Environment.Value(strVarName) = varValue
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: ConvertParam
' Description: Close all child dialogs
' Parameter:
'	- strParam
' History:
'	- 2012-02-13 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function ConvertParam(strParam)
	Dim str, arr, arr1, arr2
	On Error Resume Next
	str = strParam
	str = Replace(str, "{LOCAL_SERVER}", LOCAL_HOST_NAME)
	str = Replace(str, "{LOCAL_USER_NAME}", LOCAL_USER_NAME)
	str = Replace(str, "{RECORD_SYNC_TIMEOUT}", RECORD_SYNC_TIMEOUT)
	str = Replace(str, "{RANDOM_DATA}", OS_GenerateRandomData)
	If InStr(1, str, "{VAR:") > 0 Then
		arr1 = Split(str, "{")
		arr1(1) = Replace(arr1(1), "VAR:", "")
		arr2 = Split(arr1(1), "}")
      arr2(0) = Environment.Value(arr2(0))
		str = arr1(0) & arr2(0) & arr2(1)
	End If
	If InStr(1, str, "{RANDOM_NUMBER:") > 0 Then
		arr1 = Split(str, "{")
		arr1(1) = Replace(arr1(1), "RANDOM_NUMBER:", "")
		arr1(1) = Replace(arr1(1), "}", "")
		arr2 = Split(arr1(1), ",")
		str = OS_GenerateRandomNumber(CInt(arr2(0)),CInt(arr2(1)))
		str = arr1(0) & str
	End If
	If InStr(1, str, "{RANDOM_DATASET_ID}") > 0 Then
		str = Replace(str, "{RANDOM_DATASET_ID}", HPTrim_GetARandomDatasetID)
	End If
	If InStr(1, str, "{RANDOM_SECURITY_RANKING}") > 0 Then
		str = Replace(str, "{RANDOM_SECURITY_RANKING}", HPTrimSecurity_GetRandomSecurityRanking)
	End If
	ConvertParam = CStr(str)
	On Error Goto 0
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: GenerateTestReport
' Description:
' Parameter:
'	- strTestSetName
'	- iElapsedTime
' History:
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function GenerateTestReport(strTestSetName, iElapsedTime)
	Dim strFileName
	LogMessage("Generate test report for test set '" & strTestSetName & "'...")
	strFileName = strTestSetName & " - " & BUILD_VERSION & " - " & TimeStamp() & ".xls"
	Datatable.Export(REPORT_FOLDER & strFileName)
	FormatReport REPORT_FOLDER & strFileName, strTestSetName, iElapsedTime
	LogMessage("Generate test report for test set '" & strTestSetName & "' --> Done")
	GenerateTestReport = strFileName
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: Border
' Description: Set border for special range
' Parameter:   
'	- iFirstCol: first column in the range
'	- iLastCol: last column in the range
'	- iFirstRow: first row in the range
'	- iLastRow: last row in the range
' History: 
'	- 2010-10-10-20 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Border(iFirstCol, iLastCol, iFirstRow, iLastRow)
	Dim i, j, k
	For j = iFirstCol To iLastCol
		For i = iFirstRow To iLastRow
			For k = 8 To 11
				With objWorksheet.Cells(i,j).Borders(k)
					.LineStyle = 1
					.Weight = 2
					.ColorIndex = -4105
				End With
			Next
		Next
	Next
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: Background
' Description: Set background color for special range
' Parameter:
'	- iFirstCol: first column in the range
'	- iLastCol: last column in the range
'	- iFirstRow: first row in the range
'	- iLastRow: last row in the range
'	- iColorindex: index of background color, see reference
' History:
'	- 2010-10-10-20 | Initial Revision
' Reference:
'	- ColorIndex Property: http://msdn.microsoft.com/en-us/library/office/cc296089%28v=office.12%29.aspx
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function Background(iFirstCol, iLastCol, iFirstRow, iLastRow, iColorindex)
	Dim i, j
	For j = iFirstCol To iLastCol
		For i = iFirstRow To iLastRow
			objWorksheet.Cells(i,j).Interior.Colorindex = iColorindex
		Next
	Next
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: TimeStamp
' Description: Retrns the current Timestamp as a string in the format
'              YYYY-MM-DD_HH24-MI-SS (e.g. "2012-03-28_17-24-55")
' Parameter: none
' History:
'	- 2012-03-30 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function TimeStamp()
	Dim strTemp, tmpNow
	tmpNow = Now()
	strTemp = DatePart("yyyy",tmpNow) & "-" _
	& Right("0" & CSTR(month(tmpNow)), 2) & "-" _
	& Right("0" & CSTR(day(tmpNow)), 2) _
	& "_" _
	& Right("0" & CSTR(hour(tmpNow)), 2) & "-" _
	& Right("0" & CSTR(minute(tmpNow)), 2) & "-" _
	& Right("0" & CSTR(second(tmpNow)), 2)
	TimeStamp = strTemp
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: GetArrayIndex
' Description: Find a match of search string in an array and returns index of that string in array
' Parameter:
'	- arrSearch: array that contains all strings
'	- strSearchString: string that wants to find in array
' Return value: -1 if no match in array, otherwise is the index of search string in array
' History:
'	- 2012-04-12 | Initial Revision
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function GetArrayIndex(arrSearch, strSearchString)
   Dim iIndex
   For iIndex = 0 to Ubound(arrSearch)
	   If (trim(arrSearch(iIndex)) = trim(strSearchString)) Then
			GetArrayIndex = iIndex
			Exit Function
	   End If
   Next
   ' If loop through the array and don't find the match, return -1
   If (iIndex > Ubound(arrSearch)) Then
		GetArrayIndex = -1
   End If
End Function


'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' Function Name: FormatReport
' Description:
' Parameter:
'	- strReportFilePath: path of report file
'	- strTestSetName: name of testset file
'	- iElapsedTime: total execution time of all testset
' History:
'	- 2010-10-10-20 | Initial Revision
'	- 2013-07-02-20 | Change format report style - NamDH7
' Reference:
'	- Microsoft Excel Constants: http://msdn.microsoft.com/en-us/library/aa221100%28office.11%29.aspx
'	- ColorIndex Property: http://msdn.microsoft.com/en-us/library/office/cc296089%28v=office.12%29.aspx
'=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function FormatReport(strReportFilePath, strTestSetName, iElapsedTime)
	Dim i
	Dim intMaxRow : intMaxRow = 65536
	Dim iLastRow  : iLastRow = 0
	Dim iTotal
	Dim intRow, iPassed, iFailed, iBlocked, iNoRun, iDone
	
	OS_KillProcess LOCAL_HOST_NAME, "EXCEL.EXE"
	Set objExcel = CreateObject("Excel.Application")
	Set objWorkbook = objExcel.Workbooks.Open(strReportFilePath)
	objWorkbook.Sheets(objWorkbook.Sheets.Count).Move objWorkbook.Sheets(1)
	
	'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	' Format TestCase sheet
	'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	objExcel.Sheets("TestCase").Select
	Set objWorksheet = objWorkbook.Worksheets("TestCase")
	
	For i = 1 To intMaxRow
		If UCase(objWorksheet.Cells(i, 1).Value) = "END" Then
			iLastRow = i
			
			Exit For
		End If
	'MsgBox iLastRow
	Next
	'Reset all cells in TestCase Sheet
	objWorksheet.Cells.Interior.ColorIndex = 2
	objWorksheet.Cells.Borders.LineStyle = -4142
 	
 	'Format size and alignment of columns in testset table
 	objExcel.Range("A:B").ColumnWidth = 15
 	objExcel.Range("C:c").Columns.AutoFit
 	objExcel.Range("D:D").ColumnWidth = 90
 	objExcel.Range("D:d").WrapText = True
 	objExcel.Range("E:E").ColumnWidth = 80
 	objExcel.Range("F:F").ColumnWidth = 5
	objExcel.Range("G:U").ColumnWidth = 15
 	objExcel.Range("G:U").WrapText = False
 	
	'Set color for header and footer of testcase table
   	objExcel.Range("A1:U" & iLastRow).Interior.ColorIndex = 23
	objExcel.Range("A1:U" & iLastRow).Font.Size = 10
	objExcel.Range("A1:U" & iLastRow).Font.Name = "Tahoma"
	objExcel.Range("A1:U" & iLastRow).Font.Bold = True
	objExcel.Range("A1:U" & iLastRow).Font.ColorIndex = 2
	objExcel.Range("A1:U" & iLastRow).Borders.LineStyle = 1
	objExcel.Range("A1:U" & iLastRow).RowHeight = 25
	objExcel.Range("A1:U" & iLastRow).VerticalAlignment = -4108
	
	'Format table testcase content
	objExcel.Range("A2:U" & iLastRow-1).Interior.ColorIndex = 2
	objExcel.Range("A2:U" & iLastRow-1).Font.Bold = False
	objExcel.Range("A2:U" & iLastRow-1).Font.ColorIndex = 1
	objExcel.Range("A2:U" & iLastRow-1).Rows.AutoFit
	
	For i = 2 To iLastRow
		Select Case objWorksheet.Cells(i,1).Value
			Case "Passed"
            	objWorksheet.Cells(i,1).Font.Colorindex = 32  '#0000FF
			Case "Failed"
				objWorksheet.Cells(i,1).Font.Colorindex = 3   '#FF0000
			Case "Blocked"
				objWorksheet.Cells(i,1).Font.Colorindex = 26  '#FF00FF
			Case "Done"
				objWorksheet.Cells(i,1).Font.Colorindex = 10  '#008000
			Case Else
				'objWorksheet.Cells(i,1).Font.Colorindex = 15  '#C0C0C0
		End Select
	Next
	
	'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	' Format Testset sheet
	'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	objExcel.Sheets("TestSet").Select
	Set objWorksheet = objWorkbook.Worksheets("TestSet")
	
	intRow = 17
	iPassed = 0
	iFailed = 0
	iBlocked = 0
	iNoRun = 0
	iDone = 0
	iTotal = 0
	
	' Insert Extra Info
	For i = 1 To intRow-1
		objWorksheet.Rows("1:1").Insert
	Next
	objWorksheet.Cells(1,1).Value = "AUTOMATION TEST REPORT"
	objWorksheet.Cells(3,2).Value = "' - Test Set"
	objWorksheet.Cells(4,2).Value = "' - Test Date"
	objWorksheet.Cells(5,2).Value = "' - Elapsed Time"
	objWorksheet.Cells(6,2).Value = "' - Test Server"
	objWorksheet.Cells(7,2).Value = "' - Test Build"
	objWorksheet.Cells(9,2).Value = "' - Total Test Cases"
	objWorksheet.Cells(10,2).Value = "'     + Passed"
	objWorksheet.Cells(11,2).Value = "'     + Failed"
	objWorksheet.Cells(12,2).Value = "'     + Blocked"
	objWorksheet.Cells(13,2).Value = "'     + Done"
	objWorksheet.Cells(14,2).Value = "'     + No Run"
	objWorksheet.Cells(3,3).Value = ": " & strTestSetName
	objWorksheet.Cells(4,3).Value = ": " & Month(Now) & "-" & Day(Now) & "-" & Year(Now)
	objWorksheet.Cells(5,3).Value = ": " & iElapsedTime
	objWorksheet.Cells(6,3).Value = ": " & LOCAL_HOST_NAME
	'objWorksheet.Cells(7,3).Value = ": " & "v" & GetProductVersion(WEB_URL) & "mdm"
	
	For i = 1 To intMaxRow
		If UCase(objWorksheet.Cells(i, 1).Value) = "END" Then
			iLastRow = i
			Exit For
		End If
	Next
	For i = intRow To iLastRow
		Select Case objWorksheet.Cells(i, 5).Value
			Case "Passed"
				iPassed = iPassed + 1
			Case "Failed"
				iFailed = iFailed + 1
			Case "Blocked"
				iBlocked = iBlocked + 1
			Case "Done"
				iDone = iDone + 1
			Case "No Run"
				iNoRun = iNoRun + 1				
		End Select
	Next  
	iTotal = iPassed + iFailed + iBlocked + iDone + iNoRun
	Environment.Value("IPASSED") = iPassed
	Environment.Value("IFAILED") = iFailed
	Environment.Value("IBLOCKED") = iBlocked
	Environment.Value("INORUN") = iNoRun
	Environment.Value("ITOTAL") = iTotal
	objWorksheet.Cells(9,3).Value = ": " & iTotal
	objWorksheet.Cells(10,3).Value = ": " & iPassed & " (" & cint((iPassed/iTotal) * 100) & "%" & ")"
	objWorksheet.Cells(11,3).Value = ": " & iFailed & " (" & cint((iFailed/iTotal) * 100) & "%" &  ")"
	objWorksheet.Cells(12,3).Value = ": " & iBlocked & " (" & cint((iBlocked/iTotal) * 100) & "%" & ")"
	objWorksheet.Cells(13,3).Value = ": " & iDone & " (" & cint((iDone/iTotal) * 100) & "%" & ")"
	objWorksheet.Cells(14,3).Value = ": " & iNoRun & " (" & cint((iNoRun/iTotal) * 100) & "%" & ")"
	
	'Reset all cells in TestSet Sheet
	objWorksheet.Cells.Interior.ColorIndex = 2
	objWorksheet.Cells.Borders.LineStyle = -4142
	
	'Format title
	objWorksheet.Rows(1).HorizontalAlignment = -4131
	objWorksheet.Rows(1).Font.Bold = True
	objWorksheet.Rows(1).Font.Size = 16
	objWorksheet.Rows(1).Font.Name = "Courier New"
	objWorksheet.Rows(1).Font.ColorIndex = 23
	
	'Format report summary
	objExcel.Range("A2:G" & intRow-1).Font.Size = 10
	objExcel.Range("A2:G" & intRow-1).Font.Name = "Courier New"
	objExcel.Range("A2:G" & intRow-1).Borders.LineStyle = -4142
	
	'Format size and alignment of columns in testset table
	objExcel.Range("A" & intRow & ":A" & iLastRow).ColumnWidth = 10
	objExcel.Range("A" & intRow & ":A" & iLastRow).HorizontalAlignment = -4108
	objExcel.Range("B" & intRow & ":B" & iLastRow).ColumnWidth = 25
	objExcel.Range("B" & intRow & ":B" & iLastRow).HorizontalAlignment = -4131
	objExcel.Range("C" & intRow & ":C" & iLastRow).ColumnWidth = 90
	objExcel.Range("C" & intRow & ":C" & iLastRow).HorizontalAlignment = -4131
	objExcel.Range("C" & intRow & ":C" & iLastRow).WrapText = True
	objExcel.Range("D" & intRow & ":D" & iLastRow).ColumnWidth = 15
	objExcel.Range("D" & intRow & ":D" & iLastRow).HorizontalAlignment = -4108
	objExcel.Range("E" & intRow & ":E" & iLastRow).ColumnWidth = 15
	objExcel.Range("E" & intRow & ":E" & iLastRow).HorizontalAlignment = -4108
	objExcel.Range("F" & intRow & ":F" & iLastRow).ColumnWidth = 15
	objExcel.Range("F" & intRow & ":F" & iLastRow).HorizontalAlignment = -4108
	objExcel.Range("G" & intRow & ":G" & iLastRow).ColumnWidth = 90
	objExcel.Range("G" & intRow & ":G" & iLastRow).HorizontalAlignment = -4131
	
	'Set color for header and footer of testset table
	objExcel.Range("A" & intRow & ":G" & iLastRow).Interior.ColorIndex = 23
	objExcel.Range("A" & intRow & ":G" & iLastRow).Font.Size = 10
	objExcel.Range("A" & intRow & ":G" & iLastRow).Font.Name = "Tahoma"
	objExcel.Range("A" & intRow & ":G" & iLastRow).Font.Bold = True
	objExcel.Range("A" & intRow & ":G" & iLastRow).Font.ColorIndex = 2
	objExcel.Range("A" & intRow & ":G" & iLastRow).Borders.LineStyle = 1
	objExcel.Range("A" & intRow & ":G" & iLastRow).RowHeight = 25
	objExcel.Range("A" & intRow & ":G" & iLastRow).VerticalAlignment = -4108
	
	'Format table testset content
	objExcel.Range("A" & intRow+1 & ":G" & iLastRow-1).Interior.ColorIndex = 2
	objExcel.Range("A" & intRow+1 & ":G" & iLastRow-1).Font.Bold = False
	objExcel.Range("A" & intRow+1 & ":G" & iLastRow-1).Font.ColorIndex = 1
	objExcel.Range("A" & intRow+1 & ":G" & iLastRow-1).Rows.AutoFit
	
	For i = intRow To iLastRow
		Select Case objWorksheet.Cells(i,5).Value
			Case "Passed"
				objWorksheet.Cells(i,5).Font.Colorindex = 32
			Case "Failed"
				objWorksheet.Cells(i,5).Font.Colorindex = 3
			Case "Blocked"
				objWorksheet.Cells(i,5).Font.Colorindex = 26
			Case "Done"
				objWorksheet.Cells(i,5).Font.Colorindex = 10
			Case Else
				'objWorksheet.Cells(i,5).Font.Colorindex = 15				
		End Select
	Next
	
	'Delete Un-Reported sheets
	objExcel.DisplayAlerts = False
	objExcel.Sheets("Global").Select
	objExcel.Sheets("Global").Delete
	objExcel.Sheets("ESD").Select
	objExcel.Sheets("ESD").Delete
	For i = 3 To objExcel.Sheets.Count
		If (objExcel.Sheets(i).Name <> "TestSet") And (objExcel.Sheets(i).Name <> "TestCase") Then
			objExcel.Sheets(i).Select
			objExcel.Sheets(i).Delete
		End If
	Next
	
	'Save report
	objExcel.Sheets(1).Select
	objExcel.DisplayAlerts = True
	objExcel.ActiveWorkbook.Save
	
	'Cleanup		
	objExcel.Quit
	Set objWorksheet = Nothing
	Set objWorkbook = Nothing
	Set objExcel = Nothing

End Function

'Function GetProductVersion(strFilePath)
'	Dim objFileSystem
'	Set objFileSystem = CreateObject("Scripting.FileSystemObject")
'	GetProductVersion = objFileSystem.GetFileVersion(strFilePath)
'	Set objFileSystem = Nothing
'End Function
