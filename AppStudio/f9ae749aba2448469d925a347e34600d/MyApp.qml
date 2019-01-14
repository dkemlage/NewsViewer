/* Copyright 2018 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */


// You can run your app in Qt Creator by pressing Alt+Shift+R.
// Alternatively, you can run apps through UI using Tools > External > AppStudio > Run.
// AppStudio users frequently use the Ctrl+A and Ctrl+I commands to
// automatically indent the entirety of the .qml file.


import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
//import Esri.ArcGISRuntime 100.3

App {
    id: app
    width: 800
    height: 480
    property variant jsonObj
    property variant readyForExport:[]

    //Set your default path here
    property string path:'C:/NewsViewer/NYTimesData'

    //You can set an API key here
    property string apiKey: ''


    //-------------Control Buttons-----------//
    Rectangle{
        id:topBar
        width:parent.width
        height:apiKeyButton.height
        Button {
            id:apiKeyButton
            text:"1. Set your API Key"

            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.horizontalCenter: parent
            onClicked: {
                apiKeyEntry.open();
            }
        }

        Button {
            id:getArchive
            text:"2. Make an Archive request"
            anchors.top:apiKeyButton.top
            anchors.left: apiKeyButton.right
            anchors.leftMargin: 10
            onClicked: {
                    dateSelection.open()
            }
        }
        Button {
            id:getTopStories
            text:"2. Make a Top Stories request"
            anchors{
                top:getArchive.top
                left:getArchive.right
                leftMargin: 20
            }
            onClicked: {
                loadFile("https://api.nytimes.com/svc/topstories/v2/home.json?api-key="+app.apiKey,"top");
            }
        }
        Button {
            id:gotoFolder
            anchors{
                left:getTopStories.right
                leftMargin: 20
            }

            text:"3. Data folder"
            onClicked: {
                onLinkActivated: Qt.openUrlExternally("file:///"+app.path)
            }
        }



    }
    Rectangle{

        Popup{
            id:dateSelection
            x:app.width*.175
            y:app.height*.175
            width:app.width*.65
            height:app.height*.65
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            Text{
                id:yearText
                anchors{
                    left:parent.left
                    top:parent.top
                    margins:10
                }
                text:"Select a year:"
                font.pointSize: 12
            }

            ComboBox{
                id:yearSelection
                anchors{
                    left:yearText.right
                    verticalCenter: yearText.verticalCenter
                    leftMargin:10
                }
                width: 200
                model: [ "2016", "2017", "2018","2019" ]

            }
            Text{
                id:monthText
                anchors.top:yearSelection.bottom
                anchors.left:parent.left
                anchors.margins:10
                text:"Select a month:"
                font.pointSize: 12
            }

            ComboBox{
                id:monthSelection
                width: 200
                model: [ "1", "2", "3","4","5","6","7","8","9","10","11","12" ]
                anchors.left: monthText.right
                anchors.verticalCenter: monthText.verticalCenter
                anchors.leftMargin: 10

            }
            Button{
                id:dateOkButton
                text:"ok"
                onClicked: {
                    dateSelection.close()
                    loadFile("https://api.nytimes.com/svc/archive/v1/"+yearSelection.currentText+"/"+monthSelection.currentText+".json?api-key="+app.apiKey,"archive")
                }
                anchors{
                    bottom:parent.bottom
                    right:dateCancelButton.left
                    margins:10
                }

            }
            Button{
                id:dateCancelButton
                text:"Cancel"
                onClicked: dateSelection.visible = false
                anchors{
                    bottom:parent.bottom
                    right:parent.right
                    margins:10
                }
            }
        }
        Popup{
            id:apiKeyEntry
            x:app.width*.175
            y:app.height*.175
            width:app.width*.65
            height:app.height*.65
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
            Text{
                id:apikeyFieldName
                text:"Enter your API Key:"
                font.pointSize: 12
                anchors{
                    left:parent.left
                    margins: 10
                    top:parent.top
                }
            }
            TextField{
                id:apiKeyField
                anchors{
                    left:parent.left
                    right:parent.right
                    margins: 10
                    top:apikeyFieldName.bottom
                }
                onTextChanged: {
                    apiKey=apiKeyField.text;
                    phase1.color="chartreuse"
                }
                selectByMouse: true


            }
            Button{
                text:"close"
                anchors.bottom:parent.bottom
                anchors.left:parent.left
                anchors.margins: 10
                onClicked: {
                    apiKeyEntry.visible = false;
                }
            }
        }
    }





    //------------instructions and Status---------------//

    Rectangle{
        anchors{
            top:topBar.bottom
            bottom:processBar.top
            margins: 10
            left:parent.left
        }
        width:parent.width

        Text{
            anchors.fill: parent
            anchors.margins:20
            wrapMode: Text.WordWrap
            font.pointSize: 12
            text:"1. Enter the API key you received from registering at <a href='https://developer.nytimes.com/'>New York Times API</a>.
            <br>2. Click the type of request you want to make. If it is an Archive request, you will need to specify a year and month.
            <br>3. After it is done downloading and extracting the data, click to open the folder"
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }

    Rectangle{
        id:processBar
        width:parent.width
        height:app.height*.1
        anchors.bottom:parent.bottom
        Rectangle {
            id:phase1
            color:"chartreuse"
            border {
                width:2
                color:"green"
            }
            Text {
                anchors.centerIn: parent
                text:"API Key"
            }
            visible: {app.apiKey !=='' && app.apiKey.length===32}
            anchors.left: parent.left
            width: parent.width*.33
            height:parent.height
        }
        Rectangle {
            id:phase2
            color:"chartreuse"
            border {
                width:2
                color:"green"
            }
            Text {
                anchors.centerIn: parent
                text:"JSON Loaded"
            }
            visible:false
            anchors.bottom: app.bottom
            anchors.left: phase1.right
            width: parent.width*.33
            height:parent.height
        }
        Rectangle {
            id:phase3
            color:"chartreuse"
            border {
                width:2
                color:"green"
            }
            Text {
                anchors.centerIn: parent
                text:"Exported"
            }
            visible: false
            anchors.bottom: app.bottom
            anchors.left: phase2.right
            width: parent.width*.33
            height:parent.height
        }
    }

    //--------------File Controls----------------//




    //QML Objects needed for writing files
    FileFolder {
            id: fileFolder
        }
    File {
                id:file
            }

    //Logic to load the initial JSON file
    function loadFile(url,type){
    var xhr = new XMLHttpRequest;
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE && xhr.status===200) {
            var response = xhr.responseText;
            app.jsonObj = JSON.parse(response);
            console.log("JSON Loaded");
            phase2.visible = true;
            if(type==="top"){
                extractTopStoriesJSON();
            }
            if(type==="archive"){
                extractArchiveJSON();
            }

        }
        else if (xhr.readyState === XMLHttpRequest.DONE){
            phase1.color="red"
        }
    };
    xhr.send();
    }

    //File Writing logic
    function writeFile(fileName,Contents){
        file.path = app.path + fileName;
        console.log(file.path);
        file.open(File.OpenModeWriteOnly);
        file.write(Contents);
        file.close();
        console.log(file.error, file.errorString);
        phase3.visible = true;
    }

//////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------TOP STORIES LOGIC-------------------------------------//
//////////////////////////////////////////////////////////////////////////////////////////
    function extractTopStoriesJSON(){
        var number=0;
        var arr = app.jsonObj.results;
        var exportText ='';
        for(var i=0;i<arr.length;i++){

            var geo = arr[i].geo_facet;
            if ( geo.length != 0) {

                for (var x=0;x<geo.length;x++){
                    if(app.countries.indexOf(geo[x]) >= 0) {
                        exportText += arr[i].title + "~"; //0
                        exportText += arr[i].abstract + "~"; //1
                        exportText += geo[x] + "~"; //2
                        exportText += arr[i].url +"~"; //3
                        var media = arr[i].multimedia;
                        var mediaString = 'null'
                        if (media.length > 0) {
                            for (var h = 0;h<media.length;h++){
                                if(media[h].format === "thumbLarge"){
                                    mediaString = media[h].url;
                                }
                            }
                        }
                        exportText += mediaString + "~"; //4
                        var formattedDate = arr[i].published_date.slice(0,4)+arr[i].published_date.slice(5,7)+arr[i].published_date.slice(8,10);
                        exportText += formattedDate + "\r\n"; //5
                    }
                }

            }
        }
        writeFile("/topStoriesParsed.txt",exportText);
        phase2.visible=true;
    }


//////////////////////////////////////////////////////////////////////////////////////////
//------------------------------------ARCHIVES LOGIC------------------------------------//
//////////////////////////////////////////////////////////////////////////////////////////
    function extractArchiveJSON() {

        var arr = app.jsonObj.response.docs; //get the documents and load them into a new array
        var geoArray = []; //create a new array for collecting documents that match our countries list

        //iterate through all records
        for(var i=0;i<arr.length;i++){


            //Iterate through the keywords of each record to find geo locations
            for(var t=0;t<arr[i].keywords.length;t++){


                //the keywords have categories called "name," and "glocations" is the category with geospatial data
                //after we filter to only those articles with location data, then we check if that data works against the countries list
                if(arr[i].keywords[t].name==="glocations"){

                    if(app.countries.indexOf(arr[i].keywords[t].value)>=0){ //countries check
                        var exportString = '';
                        exportString += arr[i].headline.main + "~";
                        exportString += arr[i].snippet+ "~"; //1
                        exportString += arr[i].keywords[t].value + "~"; //2
                        exportString += arr[i].web_url+ "~"; //3
                        var mediaString = 'null'
                        var media = arr[i].multimedia;
                        if (media.length > 0) {
                            for (var h = 0;h<media.length;h++){
                                if(media[h].subtype === "thumbLarge"){
                                    mediaString = 'https://www.nytimes.com/'+media[h].url;
                                    break;
                                }
                            }
                        }
                        exportString += mediaString + "~"; //4
                        var formattedDate = arr[i].pub_date.slice(0,4)+arr[i].pub_date.slice(5,7)+arr[i].pub_date.slice(8,10);
                        exportString += formattedDate + "\r\n"; //5
                        if(geoArray.indexOf(exportString)===-1){
                        geoArray.push(exportString);
                        }
                    }
                }
            }

        }

        var month = parseInt(geoArray[0].slice(-6,-4));
        var year = parseInt(geoArray[0].slice(-10,-6));
        for (var day=1;day <=31 ;day++){
            var filecontent = ''
            for(var x=0;x<geoArray.length;x++){
                var articleDate = parseInt(geoArray[x].slice(-4,-2))
                if (articleDate === day){
                    filecontent+=geoArray[x];
                }
            }
            writeFile("/"+year+"-"+month+"-"+day+".txt",filecontent);
        }
    }



    //------------Matching Array---------------//

    property variant countries: [
        "Afghanistan",
        "Albania",
        "Algeria",
        "American Samoa",
        "Andorra",
        "Angola",
        "Anguilla",
        "Antarctica",
        "Antigua and Barbuda",
        "Argentina",
        "Armenia",
        "Aruba",
        "Australia",
        "Austria",
        "Azerbaijan",
        "Bahamas",
        "Bahrain",
        "Bangladesh",
        "Barbados",
        "Belarus",
        "Belgium",
        "Belize",
        "Benin",
        "Bermuda",
        "Bhutan",
        "Bolivia",
        "Bosnia and Herzegovina",
        "Botswana",
        "Bouvet Island",
        "Brazil",
        "British Indian Ocean Territory",
        "British Virgin Islands",
        "Brunei Darussalam",
        "Bulgaria",
        "Burkina Faso",
        "Burma",
        "Burundi",
        "Cambodia",
        "Cameroon",
        "Canada",
        "Cape Verde",
        "Cayman Islands",
        "Central African Republic",
        "Chad",
        "Chile",
        "China",
        "Christmas Island",
        "Cocos (Keeling) Islands",
        "Colombia",
        "Comoros",
        "Congo",
        "Cook Islands",
        "Costa Rica",
        "Cote d'Ivoire",
        "Croatia",
        "Cuba",
        "Cyprus",
        "Czech Republic",
        "Democratic Republic of the Congo",
        "Denmark",
        "Djibouti",
        "Dominica",
        "Dominican Republic",
        "Ecuador",
        "Egypt",
        "El Salvador",
        "Equatorial Guinea",
        "Eritrea",
        "Estonia",
        "Ethiopia",
        "Falkland Islands (Malvinas)",
        "Faroe Islands",
        "Fiji",
        "Finland",
        "France",
        "French Guiana",
        "French Polynesia",
        "French Southern and Antarctic Lands",
        "Gabon",
        "Gambia",
        "Georgia",
        "Germany",
        "Ghana",
        "Gibraltar",
        "Greece",
        "Greenland",
        "Grenada",
        "Guadeloupe",
        "Guam",
        "Guatemala",
        "Guernsey",
        "Guinea",
        "Guinea-Bissau",
        "Guyana",
        "Haiti",
        "Heard Island and McDonald Islands",
        "Holy See (Vatican City)",
        "Honduras",
        "Hong Kong",
        "Hungary",
        "Iceland",
        "India",
        "Indonesia",
        "Iran (Islamic Republic of)",
        "Iraq",
        "Ireland",
        "Isle of Man",
        "Israel",
        "Italy",
        "Jamaica",
        "Japan",
        "Jersey",
        "Jordan",
        "Kazakhstan",
        "Kenya",
        "Kiribati",
        "Korea, Democratic People's Republic of",
        "Korea, Republic of",
        "Kuwait",
        "Kyrgyzstan",
        "Lao People's Democratic Republic",
        "Latvia",
        "Lebanon",
        "Lesotho",
        "Liberia",
        "Libyan Arab Jamahiriya",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Macau",
        "Madagascar",
        "Malawi",
        "Malaysia",
        "Maldives",
        "Mali",
        "Malta",
        "Marshall Islands",
        "Martinique",
        "Mauritania",
        "Mauritius",
        "Mayotte",
        "Mexico",
        "Micronesia, Federated States of",
        "Monaco",
        "Mongolia",
        "Montenegro",
        "Montserrat",
        "Morocco",
        "Mozambique",
        "Namibia",
        "Nauru",
        "Nepal",
        "Netherlands",
        "Netherlands Antilles",
        "New Caledonia",
        "New Zealand",
        "Nicaragua",
        "Niger",
        "Nigeria",
        "Niue",
        "Norfolk Island",
        "Northern Mariana Islands",
        "Norway",
        "Oman",
        "Pakistan",
        "Palau",
        "Palestine",
        "Panama",
        "Papua New Guinea",
        "Paraguay",
        "Peru",
        "Philippines",
        "Pitcairn Islands",
        "Poland",
        "Portugal",
        "Puerto Rico",
        "Qatar",
        "Republic of Moldova",
        "Reunion",
        "Romania",
        "Russia",
        "Rwanda",
        "Saint Barthelemy",
        "Saint Helena",
        "Saint Kitts and Nevis",
        "Saint Lucia",
        "Saint Martin",
        "Saint Pierre and Miquelon",
        "Saint Vincent and the Grenadines",
        "Samoa",
        "San Marino",
        "Sao Tome and Principe",
        "Saudi Arabia",
        "Senegal",
        "Serbia",
        "Seychelles",
        "Sierra Leone",
        "Singapore",
        "Slovakia",
        "Slovenia",
        "Solomon Islands",
        "Somalia",
        "South Africa",
        "South Georgia South Sandwich Islands",
        "Spain",
        "Sri Lanka",
        "Sudan",
        "Suriname",
        "Svalbard",
        "Swaziland",
        "Sweden",
        "Switzerland",
        "Syrian Arab Republic",
        "Taiwan",
        "Tajikistan",
        "Thailand",
        "The former Yugoslav Republic of Macedonia",
        "Timor-Leste",
        "Togo",
        "Tokelau",
        "Tonga",
        "Trinidad and Tobago",
        "Tunisia",
        "Turkey",
        "Turkmenistan",
        "Turks and Caicos Islands",
        "Tuvalu",
        "Uganda",
        "Ukraine",
        "United Arab Emirates",
        "United Kingdom",
        "United Republic of Tanzania",
        "United States",
        "United States Minor Outlying Islands",
        "United States Virgin Islands",
        "Uruguay",
        "Uzbekistan",
        "Vanuatu",
        "Venezuela",
        "Viet Nam",
        "Wallis and Futuna Islands",
        "Western Sahara",
        "Yemen",
        "Zambia",
        "Zimbabwe"

    ]
}
