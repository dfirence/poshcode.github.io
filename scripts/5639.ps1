
# see http://poshcode.org/751

$jirasvc = New-WebServiceProxy -Uri "http://jra.netpost/jira//rpc/soap/jirasoapservice-v2?wsdl"
$username = "myuserid"
$password = "mypassword"

# login ###################################################################################
$token = $jirasvc.login($username,$password)

$namespace = $jirasvc.GetType().Namespace

# create a new issue ######################################################################
$issue = New-Object "$namespace.RemoteIssue"

$Jira_Component = New-Object "$namespace.RemoteComponent"
$Jira_Component.id = 12740
$Jira_Component.name = "SCM" 
 
$issue.summary = "a summary" 
$issue.description = "foo mane padme hum" 
$issue.type = "3" #Task
$issue.priority = "4" #Minor
$issue.components += $Jira_Component 
$issue.project = "TEST"

# create the issue issue 
$remoteIssue = $jirasvc.createIssue($token,$issue)

# show the new issue number 
Write-Host $remoteIssue.key

# assign to me ############################################################################
# to change the assignee, we need a remoteField 
$remoteField = New-Object "$namespace.RemoteFieldValue"
$remoteField.id = "assignee"
$remoteField.values = @( "laenenj" ) 

# assign to me 
$remoteIssue = $jirasvc.updateIssue($token,$remoteIssue.key, $remoteField)

# start working ###########################################################################
$startWorking = New-Object "$namespace.RemoteFieldValue"
$startWorking.id = "Start working"
 
$remoteIssue = $jirasvc.progressWorkflowAction($token,$remoteIssue.key,"751",$startWorking)

# add a comment ###########################################################################
$remoteComment = New-Object "$namespace.RemoteComment"
$remoteComment.body = "A first comment"
$jirasvc.addComment($token,$remoteIssue.key,$remoteComment)

# add a second comment ####################################################################
$remoteComment.body = "A second comment"
$jirasvc.addComment($token,$remoteIssue.key,$remoteComment)

# resolve #################################################################################
$resolve = New-Object "$namespace.RemoteFieldValue"
$resolve.id = "Finish"
 
$remoteIssue = $jirasvc.progressWorkflowAction($token,$remoteIssue.key,"5",$resolve)

# close ###################################################################################
$close = New-Object "$namespace.RemoteFieldValue"
$close.id = "Close"
 
$remoteIssue = $jirasvc.progressWorkflowAction($token,$remoteIssue.key,"2",$close)

