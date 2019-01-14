using Esri.ArcGISRuntime.Data;
using Esri.ArcGISRuntime.Mapping;
using System;
using System.Collections.Generic;
using System.Windows;
using System.IO;
using System.Text;
using System.Linq;
using Esri.ArcGISRuntime.Geometry;
using Esri.ArcGISRuntime.Symbology;
using System.Drawing;
using System.Windows.Documents;

namespace NewsViewer_WPF
{
    public partial class MainWindow : Window
    {

        string _NEWSFILE = @"C:\NewsViewer\NYTimesData\topStoriesParsed.txt";

        string _SHAPEFILEPATH = @"C:\NewsViewer\Shapefiles\WorldCountries.shp";

        public MainWindow()
        {
            InitializeComponent();

            Initialize();
        }

        private async void LoadTheShapefile()
        {
            try
            {
                // Get the path to the downloaded shape file.
                string myShapefilePath = _SHAPEFILEPATH;

                // Open the shape file.
                ShapefileFeatureTable myShapefileFeatureTable = await ShapefileFeatureTable.OpenAsync(myShapefilePath);

                // Create a feature layer to display the shape file.
                FeatureLayer myFeatureLayer = new FeatureLayer(myShapefileFeatureTable);

                // Set the Id of the feature layer for the shape file so we can find it later.
                myFeatureLayer.Id = "WorldCountries";

                // Add the feature layer to the map.
                MyMapView.Map.OperationalLayers.Add(myFeatureLayer);
            }
            catch (Exception e)
            {
                MessageBox.Show(e.ToString(), "Error loading the shape file.");
            }
        }

        private void ResetTheTichTextBox()
        {
            // Create a new flow document.
            FlowDocument myFlowDocument = new FlowDocument();

            // Create a new paragraph.
            Paragraph myParagraph = new Paragraph();

            // Create a new run with an empty string.
            Run myRun = new Run("");

            // Add the run to the paragraph's in-line collection.
            myParagraph.Inlines.Add(myRun);

            // Add the paragraph to the flow document's blocks collection.
            myFlowDocument.Blocks.Add(myParagraph);

            // Set the flow document to the rich text box document property.
            MyRichTextBox.Document = myFlowDocument;
        }

        private async void CreateFeatureCollectionLayerFromNYTimesArticles()
        {
            // Read the NY Times data from the text file and get back a list of each article.
            // The format of each record/article will look like:
            // [Article summary]~[Article abstract]~[Country name]~[Url to the NY times article]~[Url to an image about the NY times article]~[Date of NY Times news article]
            // Ex:
            // Netanyahu not happy with Cohen~A spokesman for Prime Minister Benjamin Netanyahu disagrees with Roger Cohen’s “pessimism.”~Israel~https://www.nytimes.com/2018/01/02/opinion/israel-future.html~https://www.nytimes.com/images/2017/12/29/opinion/29cohenWeb/29cohenWeb-thumbLarge.jpg~20180102
            List<string> myNYTimesArticles = ReadTextFile3(_NEWSFILE);

            // Get the collection of all the layers in the map.
            var myMapAllLayers = MyMapView.Map.AllLayers;

            // Create a place holder for the world countries feature layer.
            FeatureLayer myFeatureLayer = null;

            // Loop through all of the layers.
            foreach (var myLayer in myMapAllLayers)
            {
                // Get the Id of the layer.
                string myLayerName = myLayer.Id;

                // If the layer id matches world countries set that to the feature layer.
                if (myLayerName == "WorldCountries")
                { myFeatureLayer = (FeatureLayer)myLayer; }
            }

            // Get the feature table from the world countries shape file feature layer.
            FeatureTable myFeatureTable = myFeatureLayer.FeatureTable;

            // Create a new query parameters.
            QueryParameters myQueryParameters = new QueryParameters();

            // Define the where clause for the query parameters. It will select all the records in the world countries shape file feature table.
            myQueryParameters.WhereClause = "1 = 1";

            // Execute the feature query and get the results back. It will select all the records in the world countries shape file feature table.
            FeatureQueryResult myFeatureQueryResult = await myFeatureTable.QueryFeaturesAsync(myQueryParameters);

            // Create the schema for the polygon feature collection table. 
            List<Field> myFeatureCollectionAttributeFields = new List<Field>();

            // Create a field for the feature collection layer. It will contain a text field called area name that is the county name.
            Field myAreaNameField = new Field(FieldType.Text, "AreaName", "Area Name", 50);

            // Add the country name field to the list of fields that will be added to the feature collection table.
            myFeatureCollectionAttributeFields.Add(myAreaNameField);

            // Create the feature collection table based on the list of attribute fields, a polygons feature type 
            FeatureCollectionTable myFeatureCollectionTable = new FeatureCollectionTable(myFeatureCollectionAttributeFields, GeometryType.Polygon, SpatialReferences.Wgs84);

            // Create the outline symbol for the country fill symbol.
            SimpleLineSymbol mySimpleLineSymbol = new SimpleLineSymbol(SimpleLineSymbolStyle.Solid, Color.DarkBlue, 2);

            // Create the fill symbol for the country. Solid yellow, with dark blue outline.
            SimpleFillSymbol mySimpleFillSymbol = new SimpleFillSymbol(SimpleFillSymbolStyle.Solid, Color.Yellow, mySimpleLineSymbol);

            // Set the renderer of the feature collection table to be the simple fill symbol.
            myFeatureCollectionTable.Renderer = new SimpleRenderer(mySimpleFillSymbol);

            // Loop through each feature in the returned feature query results of the world countries shape file 
            foreach (Feature myFeature in myFeatureQueryResult)
            {
                // Get the geometry (aka shape) for one feature.
                Geometry myGeometry = myFeature.Geometry;

                // Loop through key/value pair of the features attributes. 
                foreach (KeyValuePair<string, object> myKeyValuePair in myFeature.Attributes)
                {
                    // Get the key (aka. field name).
                    var myKey = myKeyValuePair.Key;

                    // Get the value (aka. the text for the record of a specific field).
                    var myValue = myKeyValuePair.Value;

                    // Check is the name of the field in the shape file is 'NAME'. This represents the country name.
                    if (myKey == "NAME")
                    {
                        // Loop through each NY Times article.
                        foreach (string oneNYTimesArticle in myNYTimesArticles)
                        {
                            // Remove an embedded double quotes that may be in or surrounding the country name in the NY Times data base.
                            char[] charsToTrim = { '"' };
                            string country = oneNYTimesArticle.Split('~')[2].Trim(charsToTrim);

                            // Find a match from the shape file country feature and the NY Times country name in the article.
                            if ((string)myValue == country)
                            {
                                // Create a new polygon feature, provide geometry and attribute values.
                                Feature polyFeature = myFeatureCollectionTable.CreateFeature();
                                polyFeature.SetAttributeValue(myAreaNameField, country);
                                polyFeature.Geometry = myGeometry;

                                // Add the new features to the appropriate feature collection table.
                                await myFeatureCollectionTable.AddFeatureAsync(polyFeature);
                            }
                        }
                    }
                }
            }

            // Create a feature collection and add the feature collection tables
            FeatureCollection myFeatureCollection = new FeatureCollection();
            myFeatureCollection.Tables.Add(myFeatureCollectionTable);

            // Create a FeatureCollectionLayer 
            FeatureCollectionLayer myFeatureCollectionLayer = new FeatureCollectionLayer(myFeatureCollection);
            myFeatureCollectionLayer.Id = "Joined"; // might not be needed
            myFeatureCollectionLayer.Name = "JoinedFCL";

            // When the layer loads, zoom the map centered on the feature collection
            await myFeatureCollectionLayer.LoadAsync();

            // Add the layer to the Map's Operational Layers collection
            MyMapView.Map.OperationalLayers.Add(myFeatureCollectionLayer);
        }

        private void Initialize()
        {
            // Create a new map to display in the map view with the oceans basemap.
            MyMapView.Map = new Map(Basemap.CreateOceans());

            try
            {
                // Load the shape file in the map.
                LoadTheShapefile();

                // Add an event handler to listen for taps/clicks to start the identify operation.
                MyMapView.GeoViewTapped += MySceneView_GeoViewTapped;

                // Add an event handler for when the user chooses a day from the date picker.
                MyDatePicker.SelectedDateChanged += MyDatePicker_SelectedDateChanged;

            }
            catch (Exception e)
            {
                // Something went wrong; show an error message to the user.
                MessageBox.Show(e.ToString(), "Error initializing the application.");
            }
        }

        private void LoadNyTimesTopStories_Click(object sender, RoutedEventArgs e)
        {

            // Reset the layers in the map each time the user chooses a new set of news articles to review.
            MyMapView.Map.OperationalLayers.Clear();

            // Load the shape file in the map.
            LoadTheShapefile();

            // Reset the RichTextBox to being blank.
            ResetTheTichTextBox();

            // Construct the path and file name for the NY Times top stories articles. 
            _NEWSFILE = @"C:\NewsViewer\NYTimesData\topStoriesParsed.txt";

            // Create a feature collection layer from the NY Times articles file and add it to the map. Only those country names 
            // from the NY Times article that match those of the world countries shape file will have a feature (with geography) 
            // created with yellow symbology in the feature collection layer.
            CreateFeatureCollectionLayerFromNYTimesArticles();
        }

        private void MyDatePicker_SelectedDateChanged(object sender, System.Windows.Controls.SelectionChangedEventArgs e)
        {
            // Reset the layers in the map each time the user chooses a new set of news articles to review.
            MyMapView.Map.OperationalLayers.Clear();

            // Load the shape file in the map.
            LoadTheShapefile();

            // Reset the RichTextBox to being blank.
            ResetTheTichTextBox();

            // Construct the path and file name for the NY Times archive article based upon the date the user chose.
            DateTime myDateTime = (DateTime) MyDatePicker.SelectedDate;
            string myYear = myDateTime.Year.ToString();
            string myMonth = myDateTime.Month.ToString();
            string myDay = myDateTime.Day.ToString();
            string myFileName = @"C:\NewsViewer\NYTimesData\" + myYear + "-" + myMonth + "-" + myDay + ".txt";
            _NEWSFILE = myFileName;

            // Create a feature collection layer from the NY Times articles file and add it to the map. Only those country names 
            // from the NY Times article that match those of the world countries shape file will have a feature (with geography) 
            // created with yellow symbology in the feature collection layer.
            CreateFeatureCollectionLayerFromNYTimesArticles();
        }

        private async void MySceneView_GeoViewTapped(object sender, Esri.ArcGISRuntime.UI.Controls.GeoViewInputEventArgs e)
        {
            try
            {
                // Perform an identify across all layers, taking up to 10 results per layer.
                IReadOnlyList<IdentifyLayerResult> myIdentifyLayerResults = await MyMapView.IdentifyLayersAsync(e.Position, 15, false, 10);

                // Loop through each layer result in the collection of identify layer results.
                foreach (IdentifyLayerResult layerResult in myIdentifyLayerResults)
                {
                    // Get the layer content from the layer result.
                    ILayerContent myLayerContent = layerResult.LayerContent;

                    // Get the name of the layer content (i.e. the name of the layer).  
                    string lc_Name = myLayerContent.Name;

                    // We are only interested in the identify layer results for the created feature collection layer that 
                    // was generated from the NY Times articles.
                    if (lc_Name == "JoinedFCL")
                    {
                        // Get the sub layer results for the NY Times generated feature collection layer.
                        IReadOnlyList<IdentifyLayerResult> myIdentifyLayerResultsSubLayer = layerResult.SublayerResults;

                        // Get the first result found from identify operation on the NY Times generated feature collection layer.
                        IdentifyLayerResult myIdentifyLayerResultNYTimesFeatureCollectionTable = myIdentifyLayerResultsSubLayer.First();

                        // Get the geo-element collection from the first result. 
                        IReadOnlyList<GeoElement> myGeoElements = myIdentifyLayerResultNYTimesFeatureCollectionTable.GeoElements;

                        // Get the first geo-element in the geo-element collection. This is the identified country (via the mouse click/tap) 
                        // in the NY Times feature collection layer. 
                        GeoElement myGeoElement = myGeoElements.First();

                        // Loop through key/value pair of the features attributes in the NY Times feature collection layer. 
                        foreach (KeyValuePair<string, object> myKeyValuePair in myGeoElement.Attributes)
                        {
                            // Get the key (aka. field name).
                            var myKey = myKeyValuePair.Key;

                            // Get the value (aka. the text for the record of a specific field).
                            var myValue = myKeyValuePair.Value;

                            // Check is the name of the field in the NY Times feature collection layer 'AreaName'. This represents the country name.
                            if (myKey == "AreaName")
                            {

                                // Read the NY Times data from the text file and get back a list of each article.
                                // The format of each record/article will look like:
                                // [Article summary]~[Article abstract]~[Country name]~[Url to the NY times article]~[Url to an image about the NY times article]~[Date of NY Times news article]
                                // Ex:
                                // Netanyahu not happy with Cohen~A spokesman for Prime Minister Benjamin Netanyahu disagrees with Roger Cohen’s “pessimism.”~Israel~https://www.nytimes.com/2018/01/02/opinion/israel-future.html~https://www.nytimes.com/images/2017/12/29/opinion/29cohenWeb/29cohenWeb-thumbLarge.jpg~20180102
                                List<string> myNYTimesArticles = ReadTextFile3(_NEWSFILE);

                                // Create a FlowDocument to contain content for the RichTextBox.
                                FlowDocument myFlowDoc = new FlowDocument();

                                // Loop through each NY Times article.
                                foreach (var oneNYTimesArticle in myNYTimesArticles)
                                {
                                    // Char array to remove embedded double quotes from various NT Times strings.
                                    char[] charsToTrim = { '"' };

                                    // Get various sub-parts of the records for each NY Times article.
                                    string title = oneNYTimesArticle.Split('~')[0].Trim(charsToTrim);
                                    string absrtact = oneNYTimesArticle.Split('~')[1].Trim(charsToTrim);
                                    string country = oneNYTimesArticle.Split('~')[2].Trim(charsToTrim);
                                    string newsurl = oneNYTimesArticle.Split('~')[3].Trim(charsToTrim);
                                    string imageurl = oneNYTimesArticle.Split('~')[4].Trim(charsToTrim);
                                    string date = oneNYTimesArticle.Split('~')[5].Trim(charsToTrim);

                                    // Find a match from the NY Times feature collection layer feature country name and the NY 
                                    // Times country name in the article.
                                    if (myValue.ToString() == country)
                                    {
                                        // Create a paragraph.
                                        Paragraph myParagraph = new Paragraph();

                                        // Create a run that contains the country and a new line.
                                        Run myRun = new Run(myValue.ToString() + System.Environment.NewLine);

                                        // Create a bold that contains short title (aka news headline) of the NY Times article.
                                        Bold myBold = new Bold(new Run(title));

                                        // Create a run that contains a new line.
                                        Run myRun2 = new Run(System.Environment.NewLine);

                                        // Create a new run that contains the hyperlink to the NY Times article.
                                        Run myRun7 = new Run(newsurl);

                                        // Create a new hyperlink based on the run.
                                        Hyperlink myHP = new Hyperlink(myRun7);

                                        // Set the hyperlink to the uri of the NY Times news article.
                                        myHP.NavigateUri = new Uri(newsurl);

                                        // Wire up the event handler when the user holds down the CTRL key and presses on the hyperlink for 
                                        // the NY Times article shown in the rich text box.
                                        myHP.Click += MyHP_Click;

                                        // Add all of the sub components of the paragraph that make up what will be displayed for each NY 
                                        // Times article in the rich text box.
                                        myParagraph.Inlines.Add(myRun);
                                        myParagraph.Inlines.Add(myBold);
                                        myParagraph.Inlines.Add(myRun2);
                                        myParagraph.Inlines.Add(myHP);

                                        // Add the paragraph to the flow document's block collection.
                                        myFlowDoc.Blocks.Add(myParagraph);
                                    }
                                }

                                // Make sure that the user is able to click on hyper links in the rick text box. Requires that the .IsDocumentEnabled be true.
                                MyRichTextBox.IsDocumentEnabled = true;

                                // Add initial content to the RichTextBox.
                                MyRichTextBox.Document = myFlowDoc;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error");
            }
        }

        private void MyHP_Click(object sender, RoutedEventArgs e)
        {
            // Get the hyper link object from the sender. Meaning this is the hyper link the user clicked in the rich text box control.
            Hyperlink myHyperlink = (Hyperlink)sender;

            // Get the uri from the hyper link.
            Uri myUri = myHyperlink.NavigateUri;

            // Get the full url to the NY Times article from the uri.
            string myAbsoluteUrl = myUri.AbsoluteUri;

            // Launch an inter-net browser (or tab in an existing browser that is already open) that opens the NY Times article. 
            System.Diagnostics.Process.Start(myAbsoluteUrl);
        }

        public static List<string> ReadTextFile3(string theTextFilePath)
        {
            List<string> theReturnListOfString = new List<string>();

            try
            {
                using (System.IO.StreamReader sr = new System.IO.StreamReader(theTextFilePath))
                {
                    string line = null;
                    do
                    {
                        line = sr.ReadLine();
                        if (line != null)
                        {
                            theReturnListOfString.Add(line);
                        }
                    } while (line != null);
                }
            }
            catch (Exception e)
            {
                // Let the user know what went wrong.
                MessageBox.Show(e.Message, "The file could not be read: " + theTextFilePath);

                return null;
            }
            return theReturnListOfString;
       }
        
    }
}
