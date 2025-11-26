import 'package:get/get.dart';
import 'package:enshield_app/views/splash_view.dart';
import 'package:enshield_app/views/signin_view.dart';
import 'package:enshield_app/views/signup_view.dart';
import 'package:enshield_app/views/dashboard_view.dart';
import 'package:enshield_app/views/batch_detail_view.dart';
import 'package:enshield_app/views/rawmaterial_view.dart';
import 'package:enshield_app/views/outsourced_party_list.dart';
import 'package:enshield_app/views/outsourced_party_create.dart';
import 'package:enshield_app/views/worker_create.dart';
import 'package:enshield_app/views/worker_list.dart';
import 'package:enshield_app/views/worker_edit.dart';
import 'package:enshield_app/views/worker_assignments_view.dart';

import 'package:enshield_app/viewmodels/splash/splash_viewmodel.dart';
import 'package:enshield_app/viewmodels/signin/signin_viewmodel.dart';
import 'package:enshield_app/viewmodels/signup/signup_viewmodel.dart';
import 'package:enshield_app/viewmodels/dashboard/dashboard_viewmodel.dart';
import 'package:enshield_app/viewmodels/rawmaterial/raw_material_viewmodel.dart';
import 'package:enshield_app/viewmodels/batch_detail/batch_detail_viewmodel.dart';
import 'package:enshield_app/viewmodels/outsourced_party/outsourced_party_list_viewmodel.dart';
import 'package:enshield_app/viewmodels/outsourced_party/outsourced_party_create_viewmodel.dart';
import 'package:enshield_app/viewmodels/worker/worker_create_viewmodel.dart';
import 'package:enshield_app/viewmodels/worker/worker_list_viewmodel.dart';
import 'package:enshield_app/viewmodels/worker/worker_edit_viewmodel.dart';
import 'package:enshield_app/views/inventory_view.dart';
import 'package:enshield_app/viewmodels/inventory/inventory_viewmodel.dart';

class Routes {
  static const splash = '/';
  static const signin = '/signin';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const rawMaterial = '/raw-material';
  static const inventory = '/inventory';
  static const workOrder = '/work-order';
  static const createWorkOrder = '/create-work-order';
  static const viewWorkOrder = '/view-work-order';
  static const batchDetail = '/batch-detail';
  static const outsourcedPartyList = '/outsourced-parties';
  static const createOutsourcedParty = '/create-outsourced-party';
  static const createWorker = '/create-worker';
  static const workerList = '/workers';
  static const editWorker = '/edit-worker';
  static const workerAssignments = '/worker-assignments';
}

class AppPages {
  static final pages = [
    // 🟠 Splash Screen
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SplashViewModel>(() => SplashViewModel());
      }),
    ),

    // 🟠 Sign In
    GetPage(
      name: Routes.signin,
      page: () => const SignInView(),
      binding: BindingsBuilder(() {
        Get.put<SignInViewModel>(SignInViewModel(), permanent: false);
      }),
    ),

    // 🟠 Sign Up
    GetPage(
      name: Routes.signup,
      page: () => const SignUpView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SignUpViewModel>(() => SignUpViewModel());
      }),
    ),

    // 🟠 Dashboard
    GetPage(
      name: Routes.dashboard,
      page: () => const ProductionDashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductionDashboardViewModel>(() => ProductionDashboardViewModel());
      }),
    ),

    // 🟠 Raw Material
    GetPage(
      name: Routes.rawMaterial,
      page: () => const RawMaterialView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RawMaterialViewModel>(() => RawMaterialViewModel());
      }),
    ),

    // 🟠 Inventory Management
    GetPage(
      name: Routes.inventory,
      page: () => const InventoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InventoryViewModel>(() => InventoryViewModel());
      }),
    ),

    // 🟠 Batch Detail
    GetPage(
      name: Routes.batchDetail,
      page: () => BatchDetailView(batchId: Get.parameters['batchId'] ?? ''),
      binding: BindingsBuilder(() {
        Get.lazyPut<BatchDetailViewModel>(() => BatchDetailViewModel(Get.parameters['batchId'] ?? ''));
      }),
    ),

    // 🟠 Outsourced Parties List
    GetPage(
      name: Routes.outsourcedPartyList,
      page: () => const OutsourcedPartyListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OutsourcedPartyListViewModel>(() => OutsourcedPartyListViewModel());
      }),
    ),

    // 🟠 Create Outsourced Party
    GetPage(
      name: Routes.createOutsourcedParty,
      page: () => const CreateOutsourcedPartyView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OutsourcedPartyCreateViewModel>(() => OutsourcedPartyCreateViewModel());
      }),
    ),

    // 🟠 Create Worker
    GetPage(
      name: Routes.createWorker,
      page: () => CreateWorkerView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkerCreateViewModel>(() => WorkerCreateViewModel());
      }),
    ),

    // 🟠 Workers List
    GetPage(
      name: Routes.workerList,
      page: () => WorkerListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkerListViewModel>(() => WorkerListViewModel());
      }),
    ),

    // 🟠 Edit Worker
    GetPage(
      name: Routes.editWorker,
      page: () => EditWorkerView(workerId: Get.parameters['id'] ?? ''),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkerEditViewModel>(() => WorkerEditViewModel(Get.parameters['id'] ?? ''));
      }),
    ),

    // 🟠 Worker Assignments
    GetPage(
      name: Routes.workerAssignments,
      page: () => WorkerAssignmentsView(),
    ),
  ];
}
