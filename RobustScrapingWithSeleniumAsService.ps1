$DebugPreference = "Continue"
#add references to the Selenium DLLs 
$WebDriverPath = Resolve-Path "C:\Temp\SeleniumV2\net45\*.dll"
#unblock because often blocked by default
Unblock-File $WebDriverPath
Add-Type -Path $WebDriverPath

# Make sure to kill previous running processes. Just in case the dispose() didn't do it's job.
TRY{
    get-process chromedriver | stop-process -ErrorAction SilentlyContinue -Force | Out-Null
}CATCH{}

# Create new Object of the CLASS ChromeOptions. 
# ChromeOptions in it's turn is a CLASS of the namespace OpenQA.Selenium.Chrome
$seleniumOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions 

# Use the METHOD "AddAdditionalCapability" of the newly created object based on the ChromeOptions CLASS
$seleniumOptions.AddAdditionalCapability("useAutomationExtension", $false) 
$seleniumOptions.AddArgument("headless") # Prevent the driver from spawning the chrome windows; this scrapes without showing it.

# Because the CreateDefaultService method is a static one https://seleniumhq.github.io/selenium/docs/api/dotnet/; we create it this way and not with new-object
$seleniumService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService("C:\Temp\SeleniumV2\net45\") 
$seleniumService.HideCommandPromptWindow = $true

# Create a new object of the ChromeDriver class and feed it the options by the object of the ChromeOptions Class. 
# ChromeDriver is a class of the namespace OpenQA.Selenium.Chrome
# Run the driver as a service by providing it the service argument.
$seleniumDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($seleniumService,$seleniumOptions) 

DO{
    $error.Clear()  # $Error is used to see if the loading of the page went ok.
                    # Since this is our check, we need to clear it with each loop.

    $site = "https://www.hln.be"
    $seleniumDriver.Navigate().GoToURL($site) # DEBUG       
    
    TRY {
        # Make driver wait for 9 seconds or, if button found, immediatly go on with the rest of the script even though the 9 seconds aren't passed yet.
        $seleniumWait = New-Object -TypeName OpenQA.Selenium.Support.UI.WebDriverWait($seleniumDriver,(New-TimeSpan -Seconds 9)) 
        $seleniumWait.Until([OpenQA.Selenium.Support.UI.ExpectedConditions]::ElementIsVisible([OpenQA.Selenium.By]::XPath("/html/body/div[1]/main/div/section[1]/form/button"))) | out-null # Look for button to accept cookies.
        $seleniumDriver.FindElementByXpath("/html/body/div[1]/main/div/section[1]/form/button")
    }
    CATCH {
        # The Try{}Catch{} makes the methods ElementIsVisible and ByXPath silent.
        # Trick learned from ka-splam over at Slack.
    }
    
    # If the line above threw an error, take a screenshot
    IF  ($error[0].Exception -like "*no such element*") {
        
        Write-host "Go back rerun scrape" -ForegroundColor Cyan        
        # $seleniumDriver.GetScreenshot().SaveAsFile("C:\temp\error.jpg") 

    }ELSE{ # If no error occured, carry on with the remainder of the script.
        Write-host "Continue on friend." -ForegroundColor Yellow
        BREAK
    }
    
}WHILE($error[0].Exception -like "*no such element*") # As long as the page was not loaded correctly; keep trying.

Write-debug  "BEGIN: $(get-date)" # Record start-time

#region Debug
$seleniumWait.Message = "Time is up, let's get it."
write-host $seleniumWait.Message -ForegroundColor Blue
# $seleniumWait # Debug
#endregion

Write-debug "END: $(get-date)" # Record end-time

# Click to go to the website so we can do some scraping
$seleniumDriver.FindElementByXpath("/html/body/div[1]/main/div/section[1]/form/button").Click()

#  We shall scrape the temperature displayed on the homepage
$seleniumDriver.FindElementByClassName("weather-teaser__temperature").Text
$seleniumService.Dispose()