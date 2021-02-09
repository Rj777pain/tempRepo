import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:techanics_user/AMC/amc1.dart';
import 'package:techanics_user/AssembledPC/BuildAssembledPC.dart';
import 'package:techanics_user/CommonMethods/API.dart';
import 'package:techanics_user/CommonWidgets/BuildProductGridCard.dart';
import 'package:techanics_user/CommonWidgets/LoadingIndicator.dart';
import 'package:techanics_user/ModalClasses/ActiveServices.dart';
import 'package:techanics_user/ModalClasses/CompleteService.dart';
import 'package:techanics_user/ModalClasses/FeedBack.dart';
import 'package:techanics_user/ProductDetails/AllProducts.dart';
import 'package:techanics_user/RentalSolutions/RentalSolutions.dart';
import 'package:techanics_user/RepairSolutions/PC/PcRepair1.dart';
import 'package:techanics_user/RepairSolutions/RepairFeedBack.dart';
import '../Cart.dart';
import '../RAZOR PAY.dart';
import '../RepairSolutions/Laptop/LaptopRepair1.dart';
import '../RepairSolutions/Mobile/MobileRepair1.dart';
import 'package:techanics_user/Constants/constants.dart' as constants;
import 'package:techanics_user/Constants/globals.dart' as globals;

import '../Search.dart';
import 'AppDrawer.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Razorpay _razorPay;

  List<ActiveServices> _buildActiveServiceData = [];
  List<ActiveServices> _deliveryDetails = [];
  List<CompleteService> _completeService = [];
  List<FeedBack> _feedBack = [];
  List<Widget> _feedBackWidget = [];

  String _deliveryDetailsRepairId = "";
  String _checkOutRepairId = ""; //  Get the Repair ID to check out after Payment


  ScrollController _buildProductController = ScrollController();

  Timer _activeServicesTimer;
  Timer _onGoingServiceTimer;

  bool _buildPickUp = false;
  bool _buildOutForDelivery = false;
  bool _isLoading = true;

  TextStyle textStyle = TextStyle(
      color: Color(0xff378a8f), fontSize: 25, fontWeight: FontWeight.w700);
  TextStyle textStyle2 =
  TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 17);
  TextStyle t1 =
  TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600);
  TextStyle t2 =
  TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w300);
  SvgPicture ell = SvgPicture.asset(
    'assets/images/Ellipse 96.svg',
    height: 90,
    width: 90,
  );
  SvgPicture ic = SvgPicture.asset(
    'ssets/images/iconfinder_mobile_sercive_gear_clean_phone_iphone_ios11_4014680.svg',
    height: 50,
    width: 50,
  );

  getActiveServices() async {
    setState(() {
      _isLoading = true;
    });
    List<ActiveServices> _activeServices = [];
    _activeServices.addAll(await API().getActiveServices());
    
    _activeServices.removeLast();
    _checkForPickUp(_activeServices);
  }

  // Get the Repair Devices to be Delivered
  getONGoingServices() async {
    setState(() {
      _isLoading = true;
    });
    _deliveryDetails.clear();
    _deliveryDetails.addAll(await API().onGoingService());
    _checkForDelivery(_deliveryDetails);
  }

  _checkForDelivery(List<ActiveServices> _deliveryDetails){
    _completeService.clear();
    _onGoingServiceTimer = Timer.periodic(Duration(seconds: 5), (timer) async {

      for(int i=0; i<_deliveryDetails.length; i++) {
        _completeService.addAll(await API().checkForDelivery(_deliveryDetails[i].rpRepairid));
      }
      if(_completeService.length > 0){

        _onGoingServiceTimer.cancel();

        setState(() {
          _buildOutForDelivery = true;
        });
      }
    });
    setState(() {
      _isLoading = false;
    });
  }

  _checkForPickUp(List<ActiveServices> _activeServices) async {
    _activeServicesTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      for(int i=0; i<_activeServices.length; i++) {
        String _isTrue = await API().checkPickUpService(_activeServices[i].rpRepairid);
        if(_isTrue == "True"){
          setState(() {
            _buildActiveServiceData.clear();
            _buildActiveServiceData.add(_activeServices[i]);
            _buildPickUp = true;
          });
          _activeServicesTimer.cancel();
        }else{
          print("SERVICE NOT ACCEPTED");
        }
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  _buildSnackBar(String content){
    final snackBar = SnackBar(
      content: Text("$content"),
      duration: Duration(seconds: 3),
    );

    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  // RAZOR PAY ------->
  _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print(response.orderId);
    print(response.paymentId);
    print(response.signature);
    print("Payment Success");
    _buildSnackBar("PAYMENT SUCCESS");

    String checkOut = await API().checkOut(_checkOutRepairId);

    if(checkOut == "True"){
      setState(() {
        _buildOutForDelivery = false;
        getONGoingServices();
      });

      // Get the Repair Feedback
      Navigator.push(context, MaterialPageRoute(builder: (context) => RepairFeedBack()));
    }else{
      _buildSnackBar("Error in Checking Out");
    }
  }

  _handlePaymentError(PaymentFailureResponse response){
    print(response.message);
    print(response.code);
    print("Payment Error");

    setState(() {
      _isLoading = false;
    });

    _buildSnackBar("ERROR IN PAYMANT");
  }

  _handleExternalWallet(ExternalWalletResponse response){
    print(response.walletName);
    print("External Wallet");

    setState(() {
      _isLoading = false;
    });

    _buildSnackBar("NO EXTERNAL WALLET SUPPORTED");
  }

  getFeedBack() async {

    _feedBack.addAll(await API().getRepairFeedBack());
    setState(() {});
  }


  @override
  void initState() {
    super.initState();
    getActiveServices();
    getONGoingServices();
    getFeedBack();

    _razorPay = new Razorpay();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
        appBar: AppBar(
          // leading: Icon(Icons.clear_all,size: 40.0,),
            leading: GestureDetector(
              onTap: (){
                _scaffoldKey.currentState.openDrawer();
              },
              child: Center(
                  child: Container(
                      width: 40,
                      child: SvgPicture.asset("assets/images/Group 45.svg"))),
            ),
            actions: [
              Center(
                  child: GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Search()));
                    },
                    child: Hero(
                      tag: "Search",
                      child: Container(
                          width: 30.0,
                          child: SvgPicture.asset(
                            "assets/images/Search.svg",
                          )),
                    ),
                  )),
              SizedBox(
                width: 10.0,
              ),
              Center(
                  child: GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Cart()));
                    },
                    child: Container(
                        width: 25.0,
                        child: SvgPicture.asset(
                          "assets/images/iconfinder_shopping-cart_2561279.svg",
                        )),
                  )),
              SizedBox(
                width: 20.0,
              )
            ],
            title: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Image.asset('assets/images/logo.png',
                  fit: BoxFit.contain, height: 22),
            ),
            backgroundColor: constants.shade5),
        body: _isLoading
          ? Center(child: LoadingIndicator()) // If the Screen is Loading
          : _buildOutForDelivery
              ? _buildDeliveryScreen()
              : _buildPickUp
                    ? _buildPickScreen()  // Pick up Screen
                    : _mainBody(),    // MainBody
    );
  }

  Widget _mainBody(){
    return ListView(
      children: [
        Hero(
          tag: "setLocation",
          child: AppBar(
            leading: Center(
                child: Container(
                    child: SvgPicture.asset(
                      "assets/images/iconfinder_Map_-_Location_Solid_Style_01_2216335.svg",
                    ))),
            title: Text(
              "Set Location",
              style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff378a8f),
                  letterSpacing: 0.5
              ),
              textAlign: TextAlign.left,
            ),
            backgroundColor: Color(0xffdcf5f6),
            elevation: 0.0,
            toolbarHeight: 50,
          ),
        ),

        // for icons
       
        
        SizedBox(height: 15),
              Text(
                "How can we help you?",
                style: textStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Padding(
                 padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Hero(
                          tag: "LaptopRepair",
                          child: FlatButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => LaptopRepair1()));
                            },
                            child: circleIcon("Group 44"),
                          ),
                        ),
                        iconTitle("Laptop Repairs")
                      ],
                    ),
                    Column(
                      children: [
                        FlatButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MobileRepair1()));
                          },
                          child: Hero(
                            tag: "MobileRepair",
                            child: circleIcon(
                                "iconfinder_mobile_sercive_gear_clean_phone_iphone_ios11_4014680"),
                          ),
                        ),
                        iconTitle("Mobile Repairs")
                      ],
                    ),
                    Column(
                      children: [
                        Hero(
                          tag: "PcRepair",
                          child: FlatButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PcRepair1()));
                            },
                            child: circleIcon(
                                "iconfinder_connect_phone_pc_computer_sync_4014663"),
                          ),
                        ),
                        iconTitle("PC Repairs")
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      // ignore: deprecated_member_use
                      FlatButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RentalSolutions()));
                        },
                        child: circleIcon("Group 53"),
                      ),
                      iconTitle("Rent")
                    ],
                  ),
                  Column(
                    children: [
                      // ignore: deprecated_member_use
                      FlatButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AllProducts()));
                        },
                        child: circleIcon(
                            "iconfinder_00-ELASTOFONT-STORE-READY_bag_2703085"),
                      ),
                      iconTitle("Shop")
                    ],
                  ),
                  Column(
                    children: [
                      // ignore: deprecated_member_use
                      FlatButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => BuildAssembledPC()));
                        },
                        child: circleIcon("iconfinder_pc_2130486"),
                      ),
                      iconTitle("Custom PC's")
                    ],
                  ),
                ],
              ),),
              SizedBox(height: 15),
              Column(
                children: [
                  Hero(
                    tag: "AMC",
                    // ignore: deprecated_member_use
                    child: FlatButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AMC1()));
                      },
                      child: Center(
                        child: circleIcon("Group 54", x: 5),
                      ),
                    ),
                  ),
                  iconTitle("AMC's")
                ],
              ), 
        SizedBox(height:10),
        // offers
        Container(
          height: 200,
          color: constants.shade5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(height: 5.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Container(
                      width: MediaQuery.of(context).size.width/2 -15,
                      height: 120,
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Repair Offers!",
                            style: TextStyle(
                                color: Color(0xff609ea2),
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            "30% OFF",
                            style: TextStyle(
                                color: Color(0xff378a8f),
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 7.0),
                          Text(
                            "sdfsgsdgfgxgcvnhhhhhhhhhhhhhhhhhhhhhhhhhhfdggggggggggggg",
                            style: TextStyle(
                              color: Color(0xff609ea2),
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.white,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Container(
                      width: MediaQuery.of(context).size.width/2 - 15,
                      height: 120,
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Repair Offers!",
                            style: TextStyle(
                                color: Color(0xff609ea2),
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            "30% OFF",
                            style: TextStyle(
                                color: Color(0xff378a8f),
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 7.0),
                          Text(
                            "sdfsgsdgfgxgcvnhhhhhhhhhhhhhhhhhhhhhhhhhhfdggggggggggggg",
                            style: TextStyle(
                                color: Color(0xff609ea2), fontSize: 12),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  height: 50,
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Center(
                                child: Icon(Icons.keyboard_arrow_left)),
                          )),
                      IconButton(
                          onPressed: () {},
                          icon: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Center(
                                child:
                                Icon(Icons.keyboard_arrow_right)),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.0),

        // Featured Products
        Padding(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          child: Text(
            "Featured Products",
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),

        Container(
          height: 210,
          child: FutureBuilder(
            future: API().productList("sale"),
            builder: (context, snapshot){
              if(!snapshot.hasData){
                return ProductLoadingIndicator();
              }
              if(snapshot.hasError){
                return ProductLoadingIndicator();
              }
              return ListView.builder(
                controller: _buildProductController,
                scrollDirection: Axis.horizontal,
                physics: ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: snapshot.data.length-1,
                itemBuilder: (context, index){
                  return BuildProductGridCard(
                    productId: snapshot.data[index].pProductId,
                    productName: snapshot.data[index].pProductName,
                    imageURL: snapshot.data[index].pImg1,
                    salePrice: snapshot.data[index].pSalePrice,
                    discount: snapshot.data[index].pDiscount,
                    isRental: false,
                  );
                },
              );
            },
          ),
        ),

        SizedBox(height: 10.0,),

        Container(
          height: 210,
          child: FutureBuilder(
            future: API().productList("referbished"),
            builder: (context, snapshot){
              if(!snapshot.hasData){
                return ProductLoadingIndicator();
              }
              if(snapshot.hasError){
                return ProductLoadingIndicator();
              }
              return ListView.builder(
                controller: _buildProductController,
                scrollDirection: Axis.horizontal,
                physics: ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: snapshot.data.length-1,
                itemBuilder: (context, index){
                  return BuildProductGridCard(
                    productId: snapshot.data[index].pProductId,
                    productName: snapshot.data[index].pProductName,
                    imageURL: snapshot.data[index].pImg1,
                    salePrice: snapshot.data[index].pSalePrice,
                    discount: snapshot.data[index].pDiscount,
                    isRental: false,
                  );
                },
              );
            },
          ),
        ),

        Center(
          child: Container(
            height: 50,
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      _buildProductController.animateTo(0, duration: Duration(milliseconds: 600), curve: Curves.easeIn);
                    },
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: Color(0xff609ea2),
                      child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_left,
                            color: Colors.white,
                          )),
                    )),
                IconButton(
                    onPressed: () {
                      _buildProductController.animateTo(2, duration: Duration(milliseconds: 600), curve: Curves.easeIn);
                    },
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: Color(0xff609ea2),
                      child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.white,
                          )),
                    )),
              ],
            ),
          ),
        ),


        //  how we work
        
            Container(
               
              decoration:BoxDecoration(
                  color: Color(0xff609ea2),
                  border:Border(bottom:BorderSide(color: Color(0xff609ea2),width:0))
              ),
              child: Padding(
                padding: EdgeInsets.only(top:20,bottom:10),
                child: Text(
                  "How We Work ?",
                  style: textStyle.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: Container(
                height: 400,
                alignment:Alignment.topCenter,
                padding:EdgeInsets.only(bottom:10.0),
                decoration:BoxDecoration(
                  color: Color(0xff609ea2),
                  border:Border.all(color: Color(0xff609ea2),width:0)
              ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(20)),
                            child: Center(
                              child: SvgPicture.asset(
                                "assets/images/Group 55.svg",
                                height: 70,
                                width: 70,
                              ),
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 10,
                            color: Colors.white,
                          ),
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            child: SvgPicture.asset(
                              "assets/images/Group 33.svg",
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 10,
                            color: Colors.white,
                          ),
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                "assets/images/- FLAT.svg",
                                height: 60,
                                width: 60,
                              ),
                            ),
                          ),
                        ]),
                    Container(
                      width: 200,
                      padding: EdgeInsets.only(left: 30, top: 5),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                                width: 150,
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                  "Choose the type  of Repair",
                                  style: t1,
                                  textAlign: TextAlign.center,
                                )),
                          ),
                          Text(
                            "Choose the type of gadget you want to repair  and tell us about the issue in a user friendly way.",
                            style: t2,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 35),
                          Container(
                              width: 150,
                              padding: EdgeInsets.only(bottom: 10),
                              child: Center(
                                  child: Text(
                                    "Choose the  Time-Slot",
                                    style: t1,
                                    textAlign: TextAlign.center,
                                  ))),
                          Text(
                            "Choose the Time slot according  to your convenience",
                            style: t2,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 35),
                          Container(
                              width: 150,
                              padding: EdgeInsets.only(bottom: 10),
                              child: Center(
                                  child: Text(
                                    "Hassle-free Services",
                                    style: t1,
                                    textAlign: TextAlign.center,
                                  ))),
                          Text(
                            "Our Technician will be at your service till  your device is handed back to you safel",
                            style: t2,
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        

        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text("Customer Reviews",
              style: TextStyle(color: Colors.black, fontSize: 25),
              textAlign: TextAlign.center),
        ),
        CarouselSlider(
          options: CarouselOptions(
            enableInfiniteScroll: false,
            viewportFraction: 1.0,
            disableCenter: true,
            autoPlay: false,
            autoPlayAnimationDuration: Duration(milliseconds: 800),
          ),
          items: _feedBack.map((e) {
            return Padding(
              padding: EdgeInsets.only(left:15.0,right:15.0,bottom: 15.0),
              child: Card(
                elevation: 5,
                child: Container(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            height: 100,
                            width: 100,

                            child: SvgPicture.asset(
                              "assets/images/User.svg",
                            ),
                          ),
                        ),
                        SizedBox(width:15),
                        Container(

                          width: 200,
                          alignment: Alignment.center,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${e.uName}",
                                  style: t1.copyWith(color: Colors.black),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical:10.0, horizontal: 7.0),
                                  child: Text(
                                    "${e.rpUreview}",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic),


                                  ),
                                ),
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < 4 ? Icons.star : Icons.star_border,
                                      );}))
                              ]),
                        )
                      ],
                    )),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildPickScreen(){
    return ListView(
      children: [
        CarouselSlider(
          options: CarouselOptions(
              viewportFraction:1.0,
              disableCenter:true,
              autoPlay: false,
              autoPlayAnimationDuration: Duration(milliseconds: 800)
          ),
          items: [
            "${constants.kImageApi}" + "${_buildActiveServiceData[0].rpPic1.substring(10, _buildActiveServiceData[0].rpPic1.length)}",
            "${constants.kImageApi}" + "${_buildActiveServiceData[0].rpPic2.substring(10, _buildActiveServiceData[0].rpPic1.length)}",
          ].map((e){
            return CachedNetworkImage(
              imageUrl: e,
              placeholder: (context, url) => Container(
                  height: 20.0,
                  width: 20.0,
                  child: Center(
                      child: Container(
                          height: 50.0,
                          width: 50.0,
                          child: Image(
                            image: AssetImage("assets/images/error.jpg"),
                          )))),
              errorWidget: (context, url, error) =>
                  Image(
                    image: AssetImage("assets/images/error.jpg"),
                  ),
            );
          }).toList(),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.0,),
              Row(
                children: [
                  Text(
                    "Issue: ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0
                    ),
                  ),
                  Text(
                    "${_buildActiveServiceData[0].rpIssue}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.0,),
              Row(
                children: [
                  Text(
                    "Model: ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0
                    ),
                  ),
                  Text(
                    "${_buildActiveServiceData[0].rpModelname}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.0,),
              Row(
                children: [
                  Text(
                    "Brand: ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0
                    ),
                  ),
                  Text(
                    "${_buildActiveServiceData[0].rpBrand}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.0,),
              Row(
                children: [
                  Text(
                    "Date: ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0
                    ),
                  ),
                  Text(
                    "${_buildActiveServiceData[0].rpDate}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.0,),
              Row(
                children: [
                  Text(
                    "Time: ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0
                    ),
                  ),
                  Text(
                    "${_buildActiveServiceData[0].rpTime}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.0,),

              Center(
                child: Text(
                  "Allow Device to Pick up ?",
                  style: TextStyle(
                    color: constants.shade4,
                    fontSize: 18.0,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),

              SizedBox(height: 10.0,),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RaisedButton(
                    color: constants.shade5,
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      print("acccepting");
                      bool _acceptRequest = await API().acceptPickUpRequest(_buildActiveServiceData[0].rpRepairid);
                      print(_acceptRequest);
                      setState(() {
                        _isLoading = false;
                      });

                      if(_acceptRequest){
                        setState(() {
                          _buildPickUp = false;
                        });
                        getONGoingServices();
                      }else{
                        _buildSnackBar("Error Accepting Pick Up Request");
                      }
                    },
                    child: Text(
                      "YES",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3
                      ),
                    ),
                  ),

                  RaisedButton(
                    color: constants.shade5,
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      String response = await API().declinePickUp(_buildActiveServiceData[0].rpRepairid);
                      response == "True"
                          ? setState((){_buildPickUp = false;_isLoading = false;})
                          : _buildSnackBar("Error Declining Pick UP");

                      if(response == "True"){
                        setState(() {
                          _buildPickUp = false;
                          _isLoading = false;
                        });
                        getActiveServices();
                      }
                    },
                    child: Text(
                      "NO",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 10.0,),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDeliveryScreen(){
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: BouncingScrollPhysics(),
      itemCount: _completeService.length,
      itemBuilder: (context, index){
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height ,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                "Technician Details",
                style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16.0,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600
                ),
              ),

              SizedBox(height: 10.0,),

              Text(
                "Name: ${_completeService[index].seName}",
                style: TextStyle(
                    color: Colors.grey[900],
                    letterSpacing: 0.2,
                    fontSize: 15.0
                ),
              ),

              Text(
                "Mobile: ${_completeService[index].seMobile}",
                style: TextStyle(
                    color: Colors.grey[900],
                    letterSpacing: 0.2,
                    fontSize: 15.0
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),
                child: Divider(
                  height: 1.0,
                  color: constants.shade4,
                ),
              ),

              Text(
                "Your device ${_completeService[index].rpBrand} ${_completeService[index].rpModelname} has been repaired and our Technician is out for Delivery,",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: constants.shade4,
                    letterSpacing: 0.3,
                    fontSize: 17.0,
                    fontWeight: FontWeight.w500
                ),
              ),

              SizedBox(height: 25.0,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Divider(
                  height: 1.0,
                  color: constants.shade4,
                ),
              ),

              SizedBox(height: 9.0,),

              Text(
                "Repair Bill",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    fontSize: 15.0
                ),
              ),

              SizedBox(height: 20.0,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Serial Number :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4
                          ),
                        ),

                        SizedBox(height: 3.0,),

                        Text(
                          "Amount :",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4
                          ),
                        )
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_completeService[index].rpSrno}",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4
                          ),
                        ),

                        SizedBox(height: 3.0,),

                        Text(
                          "${_completeService[index].rpAmount}",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

              SizedBox(height: 3.0,),

              Text(
                "Description",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4
                ),
              ),
              SizedBox(height: 1.0,),
              Text(
                "${_completeService[index].rpDescription}",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2
                ),
              ),

              SizedBox(height: 10.0,),

              Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  color: constants.shade5,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    Pay().openCheckOut(_razorPay, _completeService[index].rpAmount);
                    _checkOutRepairId = _completeService[index].rpRepairid;
                  },
                  child: Text(
                    "PAY NOW",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget iconTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(title),
    );
  }

  Widget circleIcon(String iconName, {double x = 0}) {
    return Center(
      child: Card(
        shape: CircleBorder(),
        elevation: 10.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              // color: Colors.brown,
              // padding: EdgeInsets.only(top:20),
                alignment: Alignment.center,
                child: Container(
                  width: 60.0,
                    height: 60.0,
                  decoration: BoxDecoration(
                    color: constants.shade5,
                    borderRadius: BorderRadius.all(Radius.circular(100.0)),
                  ),
                )
            ),
            Container(
                padding: EdgeInsets.only(left: x),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/$iconName.svg',
                  height: 30,
                  width: 30,
                ))
          ],
        ),
      ),
    );
  }
}


