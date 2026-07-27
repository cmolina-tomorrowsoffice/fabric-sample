[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Replace"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared DefaultDestination = Lakehouse.Contents([EnableFolding = false]){[workspaceId = "802a723a-7051-4347-9b52-da12ff6e59c3"]}[Data]{[lakehouseId = "4b0c81b7-cc53-4316-924b-14dabea091ab"]}[Data];
[BindToDefaultDestination = true]
shared Customers = let
  Source = OData.Feed("https://services.odata.org/v4/northwind/northwind.svc/", null, [Implementation = "2.0"]),
  #"Navigation 1" = Source{[Name = "Customers", Signature = "table"]}[Data]
in
  #"Navigation 1";
[BindToDefaultDestination = true]
shared Orders = let
  Source = OData.Feed("https://services.odata.org/v4/northwind/northwind.svc/", null, [Implementation = "2.0"]),
  #"Navigation 1" = Source{[Name = "Orders", Signature = "table"]}[Data],
  #"Grouped rows" = Table.Group(#"Navigation 1", {"CustomerID"}, {{"Count", each Table.RowCount(_), Int64.Type}}),
  #"Filtered rows" = Table.SelectRows(#"Grouped rows", each [Count] >= min_count)
in
  #"Filtered rows";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Merge_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "Count", DestinationColumnName = "Count"], [SourceColumnName = "CustomerID", DestinationColumnName = "CustomerID"], [SourceColumnName = "CompanyName", DestinationColumnName = "CompanyName"], [SourceColumnName = "Rank", DestinationColumnName = "Rank"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared Merge = let
  Source = Table.NestedJoin(Customers, {"CustomerID"}, Orders, {"CustomerID"}, "Orders (2)", JoinKind.LeftOuter),
  #"Removed other columns" = Table.SelectColumns(Source, {"Orders (2)", "CustomerID", "CompanyName"}),
  #"Expanded Orders (2)" = Table.ExpandTableColumn(#"Removed other columns", "Orders (2)", {"Count"}, {"Count"}),
  #"Added rank column" = Table.AddRankColumn(#"Expanded Orders (2)", "Rank", {{"Count", Order.Descending}})
in
  #"Added rank column";
shared Merge_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "802a723a-7051-4347-9b52-da12ff6e59c3"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "4b0c81b7-cc53-4316-924b-14dabea091ab"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "northwind", ItemKind = "Table"]}[Data]
in
  TableNavigation;
shared min_count = 1 meta [IsParameterQuery = true, IsParameterQueryRequired = false, Type = type number, DefaultValue = null];
