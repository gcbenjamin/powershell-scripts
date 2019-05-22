#Get all branches on remote and place in array. Format of strings in array is for example "3 months ago|origin/branch-name"
$branches = git branch -r --sort=-committerdate --format="%(committerdate:relative)|%(refname:short)|%(refname:lstrip=3)"
#Loop through all branches
ForEach ($branch in $branches)
{
	#split the branch between last commit time and branch name
	$split = $branch.Split("|")
	try
	{	
		#check if the last commit date is 4 months or more
		if($split[0] -match "((^([4-9]|10|11|12) month)|year)")
		{
			$splitBranch = $split[1].Split("/")
			#tag the branch
			git tag archive/$split[2] $split[1]
			#delete the branch
			git push --delete $splitBranch[0] $split[2]
			#add the archived branch name to a text file
			Add-Content .\archived.txt $split[1]
		}
	}
	catch
	{
		#log any branches that failed
		Add-Content .\archiveFailures.txt $split[1]
	}
}
#push all newly created tags
git push --tags

#to restore archived branch
#git checkout -b <branchname> archive/<branchname>
