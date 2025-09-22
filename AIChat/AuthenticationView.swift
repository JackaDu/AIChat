import SwiftUI

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var appwriteService: AppwriteService
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("英语错词本")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("智能学习，高效记忆")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Authentication Form
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("邮箱")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入邮箱地址", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Name Field (only for sign up)
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("姓名")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("请输入姓名", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Sign In/Up Button
                    Button(action: {
                        Task {
                            await handleAuthentication()
                        }
                    }) {
                        HStack {
                            if appwriteService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignUp ? "注册" : "登录")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                        )
                    }
                    .disabled(!isFormValid || appwriteService.isLoading)
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                            clearForm()
                        }
                    }) {
                        Text(isSignUp ? "已有账号？点击登录" : "没有账号？点击注册")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                    
                    // 测试用户快速登录按钮
                    if !isSignUp {
                        Button(action: {
                            Task {
                                await quickLoginWithTestUser()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title3)
                                
                                Text("快速登录测试账号")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.orange)
                            )
                        }
                        .disabled(appwriteService.isLoading)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("认证错误", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if isFormValid && !appwriteService.isLoading {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        }
    }
    
    // MARK: - Methods
    
    private func handleAuthentication() async {
        do {
            if isSignUp {
                try await appwriteService.signUp(email: email, password: password, name: name)
            } else {
                try await appwriteService.signIn(email: email, password: password)
            }
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        name = ""
    }
    
    private func quickLoginWithTestUser() async {
        // 自动填充测试用户信息
        email = "980466479@qq.com"
        password = "test1234"
        
        // 执行登录
        do {
            try await appwriteService.signIn(email: email, password: password)
        } catch {
            alertMessage = "快速登录失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
