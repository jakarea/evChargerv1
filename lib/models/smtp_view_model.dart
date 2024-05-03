class SmtpViewModel{
  int? id;
  String? email;
  String? password;

  SmtpViewModel({
    this.id,
    this.email,
    this.password,
  });

  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String, dynamic>{};

    data['email'] = email;
    data['password'] = password;

    return data;
  }

  factory SmtpViewModel.fromJson(Map<String, dynamic> json){
    return SmtpViewModel(
        id: json['id'],
        email: json['email'],
        password: json ['password'],
    );
  }
}