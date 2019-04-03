$DebugPreference = "Continue"
#add references to the Selenium DLLs 
$WebDriverPath = Resolve-Path "C:\Temp\SeleniumV2\net45\*.dll"
#unblock because often blocked by default
Unblock-File $WebDriverPath
Add-Type -Path $WebDriverPath

# kill a "on the loose" process before we start.
get-process chromedriver | stop-process -ErrorAction SilentlyContinue -Force | out-null

# Create new Object of the class ChromeOptions. ChromeOptions in it's turn is a Class of the namespace OpenQA.Selenium.Chrome
$seleniumOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions 

# Use the method AddAdditionalCapability of the newly created object based on the ChromeOptions Class
$seleniumOptions.AddAdditionalCapability("useAutomationExtension", $false) 
$seleniumOptions.AddArgument("headless") # Prevent the driver from spawning the chrome windows; this scrapes without showing it.
# Create a new object of the ChromeDriver class and feed it the options by the object of the ChromeOptions Class. 
# ChromeDriver is a class of the namespace OpenQA.Selenium.Chrome
$seleniumDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($seleniumOptions) 

cls

# Since it often seems to happen that the driver doesn't correctly load a page
# I have implemented a test to check against that and if the page is not loaded,
# to reload the page and try again until it finally does load.

# I tried with if( $seleniumDriver.FindElementByXpath("/html/body/div[1]/main/div/section[1]/form/button"))
# but if it does not find anything, a check against it seems impossible. This is why i use error to check against.

DO{
    $error.Clear() # Since this is our check, we need to clear it with each loop.

    # Simulate a failing scrape situation.
    $site = @("https://www.hln.b","https://www.hln.be") # DEBUG      
    $seleniumDriver.Navigate().GoToURL(($site | Get-Random)) # DEBUG    
    try {
        $seleniumWait = New-Object -TypeName OpenQA.Selenium.Support.UI.WebDriverWait($seleniumDriver,(New-TimeSpan -Seconds 9)) # Make driver wait for 9 seconds or, if button found, go on with rest of script.
        $seleniumWait.Until([OpenQA.Selenium.Support.UI.ExpectedConditions]::ElementIsVisible([OpenQA.Selenium.By]::XPath("/html/body/div[1]/main/div/section[1]/form/button"))) | out-null
        $seleniumDriver.FindElementByXpath("/html/body/div[1]/main/div/section[1]/form/button")
    }
    catch {
        # The Try{}Catch{} makes the methods ElementIsVisible and ByXPath silent.
        # Trick learned from ka-splam over at Stack.
    }
    
    # If the line above threw an error, take a screenshot
    IF  ($error[0].Exception -like "*no such element*") {
        
        Write-host "Go back rerun scrape" -ForegroundColor Cyan        
        $seleniumDriver.GetScreenshot().SaveAsFile("C:\temp\error.jpg") 

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
$seleniumDriver.Quit()	
