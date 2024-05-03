class GroupViewModel {
  final int? id;
  String groupName;
  String status;

  GroupViewModel({
    this.id,
    required this.groupName,
    required this.status
  });

  /// Converting data to json format
  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String, dynamic>{};

    data['group_name'] = groupName;
    data['status'] = status;

    return data;
  }

  /// Factory constructor to create a GroupViewModel from a Map
  factory GroupViewModel.fromJson(Map<String, dynamic> json){
    return GroupViewModel(
        id: json['id'],
        groupName: json['group_name'],
        status: json ['status']
    );
  }
}