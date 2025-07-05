import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/createPostPage/post_upload_controller.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class UploadProgressWidget extends StatelessWidget {
  final PostUploadController controller = Get.find<PostUploadController>();

  UploadProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Obx(() {
      if (!controller.isUploading.value) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppBackgroundStyles.secondaryBackground(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        controller.uploadSuccess.value
                            ? Colors.green.withOpacity(0.1)
                            : controller.uploadError.value.isNotEmpty
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    controller.uploadSuccess.value
                        ? Icons.check_circle
                        : controller.uploadError.value.isNotEmpty
                        ? Icons.error
                        : Icons.cloud_upload,
                    color:
                        controller.uploadSuccess.value
                            ? Colors.green
                            : controller.uploadError.value.isNotEmpty
                            ? Colors.red
                            : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.uploadError.value.isNotEmpty
                            ? 'Đăng bài thất bại'
                            : 'Đang đăng bài viết',
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(isDarkMode),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.uploadStatus.value,
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(
                            isDarkMode,
                          ).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cancel button
                if (controller.isUploading.value &&
                    !controller.uploadSuccess.value)
                  GestureDetector(
                    onTap: controller.cancelUpload,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                    ),
                  ),
              ],
            ),

            // Progress bar
            if (controller.isUploading.value &&
                !controller.uploadSuccess.value &&
                controller.uploadError.value.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: controller.uploadProgress.value,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(controller.uploadProgress.value * 100).toInt()}%',
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(
                            isDarkMode,
                          ).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(
                            isDarkMode,
                          ).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            if (controller.uploadError.value.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    controller.uploadError.value,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}
