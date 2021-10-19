*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           OperatingSystem
Library           RPA.Robocorp.Vault
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.FileSystem
Library           Dialogs
Library           RPA.Robocorp.WorkItems
Library           Collections
Library           RPA.Robocorp.Vault
Library           RPA.Archive
#Suite Teardown    Close All Browsers

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    url
    Open Available Browser    ${secret}[url]

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    class:modal
    Click Button    class:btn-dark

*** Keywords ***
Get orders
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=True
    ${orders}=  Read table from CSV    orders.csv
    [Return]    ${orders}

*** Keywords ***
Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[4]/input    ${order}[Address]

*** Keywords ***
Preview the robot
    Click Element When Visible    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

*** Keywords ***
Submit the order
    Click Button    //*[@id='order']
    Page Should Contain Element    //*[@id="receipt"]

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}${order}.pdf
    ${pdf}    Set Variable    ${CURDIR}${/}output${/}${order}.pdf
    [Return]    ${pdf}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order}.png
    ${screenshot}    Set Variable    ${CURDIR}${/}output${/}${order}.png
    [Return]    ${screenshot}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log     ${pdf}
    Open Pdf    ${pdf}   
    Add Watermark Image To Pdf  ${screenshot}   ${pdf}
    Close Pdf

*** Keywords ***
Go to order another robot
    Click Element When Visible    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}    orders.zip

*** Keywords ***
Get URL From User
    ${URL} =	Get Value From User    Please provide the URL of the orders.csv! 
    # Hint, it's https://robotsparebinindustries.com/orders.csv
    [Return]    ${URL}

*** Keywords ***
Log Out And Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${URL}=    Get URL From User
    Open the robot order website
     ${orders}=    Get orders    ${URL}
     FOR    ${order}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${order}
         Wait Until Keyword Succeeds    10x    2s    Preview the robot
         Wait Until Keyword Succeeds    10x    2s    Submit the order
         ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
         ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
     END
    Create a ZIP file of the receipts
    [Teardown]    Log Out And Close The Browser