import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
from tkinter.font import Font
import subprocess
import re
import os
import threadin
import sys
import time
import webbrowser

# 关于程序执行路径的问题
if getattr(sys, 'frozen', False):  # 打包成exe的情况
    application_path = os.path.dirname(sys.executable)
else:  # 在开发环境中运行
    application_path = os.path.dirname(__file__)

class AlephManager:
    def __init__(self, root):
        self.root = root
        self.root.title("Aleph 分享助手-v1.0.5-作者：层林尽染")
        self.root.geometry("700x700")
        self.app_path = application_path

        # 设置程序图标
        self.icon_path = os.path.join(self.app_path, "assets", "aleph_managerGUI.ico")
        if os.path.exists(self.icon_path):
            self.root.iconbitmap(self.icon_path)

        # 设置 aleph.bat 文件的路径
        self.aleph_bat_path = os.path.join(self.app_path, "tools", "aleph.bat")

        # 创建一个样式
        style = ttk.Style()

        # 自定义 TLabelframe 样式，设置标题字体
        style.configure("Big.TLabelframe.Label", font=("Microsoft YaHei UI", 14, "bold"))
        
        # 创建主框架
        main_frame = ttk.Frame(root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # 账户管理框架
        account_frame = ttk.LabelFrame(main_frame, text="账户管理", padding="10", style="Big.TLabelframe")
        account_frame.pack(fill=tk.X, pady=5)

        # 创建账户部分
        create_frame = ttk.Frame(account_frame)
        create_frame.pack(fill=tk.X, pady=5)
        
        ttk.Label(create_frame, text="创建新账户:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.EW)
        self.account_name_var = tk.StringVar()
        ttk.Entry(create_frame, textvariable=self.account_name_var, width=36).grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(create_frame, text="【创建】", command=self.create_account).grid(row=0, column=2, padx=5, pady=5)

        # 账户列表部分
        list_frame = ttk.Frame(account_frame)
        list_frame.pack(fill=tk.X, pady=5)
        
        ttk.Label(list_frame, text="当前账户名:").grid(row=0, column=0, padx=5, pady=5, sticky=tk.EW)
        self.account_list_var = tk.StringVar()
        self.account_combo = ttk.Combobox(list_frame, textvariable=self.account_list_var, width=36, state="readonly")
        self.account_combo.grid(row=0, column=1, padx=5, pady=5)
        ttk.Button(list_frame, text="切换账户", command=self.switch_account).grid(row=0, column=2, padx=2, pady=5)
        ttk.Button(list_frame, text="删除账户", command=self.delete_account).grid(row=0, column=3, padx=2, pady=5)
        ttk.Button(list_frame, text="刷新账户列表", command=self.refresh_accounts).grid(row=1, column=2, padx=2, pady=5)
        ttk.Button(list_frame, text="显示账户文件", command=self.show_file_list).grid(row=1, column=3, padx=2, pady=5)
        # 新增按钮：
        ttk.Button(list_frame, text="关于IPFS↗", command=self.open_gateway).grid(row=1, column=4, padx=2, pady=5)

        # Pin操作框架
        pin_frame = ttk.LabelFrame(main_frame, text="CID pin&删除操作", padding="10", style="Big.TLabelframe")
        pin_frame.pack(fill=tk.X, pady=5)

        pin_input_frame = ttk.Frame(pin_frame)
        pin_input_frame.pack(fill=tk.X, pady=(0, 5))  # 修改为顶部间距为0，底部间距为5
        
        ttk.Label(pin_input_frame, text="CID列表\n(v0格式):").grid(row=0, column=0, padx=5, pady=(0, 7), sticky=tk.NW)  # 修改为顶部对齐且无上间距

        # 使用Text控件代替Entry，支持多行输入
        self.cid_text = tk.Text(pin_input_frame, width=65, height=9)
        self.cid_text.grid(row=0, column=1, padx=5, pady=(0, 7), rowspan=2)  # 修改为无上间距
        
        # 按钮框架，垂直排列
        pin_buttons_frame = ttk.Frame(pin_input_frame)
        pin_buttons_frame.grid(row=0, column=2, padx=5, pady=(0, 5), rowspan=2)
        
        ttk.Button(pin_buttons_frame, text="粘贴", command=self.paste_cid).pack(fill=tk.X, pady=2)
        ttk.Button(pin_buttons_frame, text="清空", command=self.clear_cid).pack(fill=tk.X, pady=2)
        ttk.Button(pin_buttons_frame, text="【PIN】", command=self.pin_cid).pack(fill=tk.X, pady=2)
        ttk.Button(pin_buttons_frame, text="删除", command=self.delete_cid).pack(fill=tk.X, pady=2)
        
        # 日志框架
        log_frame = ttk.LabelFrame(main_frame, text="操作日志", padding="10", style="Big.TLabelframe")
        log_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        
        ## 添加带有水平和垂直滚动条的日志文本框
        log_container = ttk.Frame(log_frame)
        log_container.pack(fill=tk.BOTH, expand=True)
        
        ## 创建垂直滚动条
        v_scrollbar = ttk.Scrollbar(log_container, orient=tk.VERTICAL)
        v_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        ## 创建水平滚动条
        h_scrollbar = ttk.Scrollbar(log_container, orient=tk.HORIZONTAL)
        h_scrollbar.pack(side=tk.BOTTOM, fill=tk.X)
        
        ## 创建文本框并关联滚动条
        self.log_text = tk.Text(log_container, wrap=tk.NONE, width=80, height=15,
                              yscrollcommand=v_scrollbar.set, 
                              xscrollcommand=h_scrollbar.set)
        self.log_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        ## 配置滚动条与文本框的关联
        v_scrollbar.config(command=self.log_text.yview)
        h_scrollbar.config(command=self.log_text.xview)
        
        # 状态栏
        self.status_var = tk.StringVar()
        self.status_var.set("准备就绪")
        ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W).pack(fill=tk.X, pady=5)
        
        # 初始化
        self.refresh_accounts()
    
    def run_command(self, command, input_text=None):
        """运行命令并返回输出"""
        self.log("执行命令: " + " ".join(command) if isinstance(command, list) else command)
        
        # 检测命令中是否包含 --json 参数
        has_json_flag = False
        if isinstance(command, list):
            has_json_flag = "--json" in command
        elif isinstance(command, str):
            has_json_flag = "--json" in command.split()
        
        try:
            # 确保命令是适当的格式
            if isinstance(command, str):
                shell = True
            else:
                shell = False

            # 创建startupinfo对象，用于隐藏命令行窗口（仅适用于Windows）
            startupinfo = None
            if sys.platform == "win32":
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                startupinfo.wShowWindow = subprocess.SW_HIDE
                    
            # 创建进程，明确指定编码为utf-8
            process = subprocess.Popen(
                command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=False,  # 使用二进制模式
                shell=shell,
                startupinfo=startupinfo  # 添加startupinfo参数
            )
            
            # 如果有输入文本，需要将其编码
            input_bytes = input_text.encode('utf-8') if input_text else None
            
            # 读取输出
            stdout_bytes, stderr_bytes = process.communicate(input=input_bytes)
            
            # 尝试使用utf-8解码，忽略错误
            stdout = stdout_bytes.decode('utf-8', errors='replace') if stdout_bytes else ""
            stderr = stderr_bytes.decode('utf-8', errors='replace') if stderr_bytes else ""
            
            # 只有不是 --json 命令时才打印 stdout
            if stdout and not has_json_flag:
                self.log("输出: " + stdout)
            if stderr:
                self.log("错误: " + stderr)
                
            return stdout, stderr, process.returncode
        except Exception as e:
            error_msg = f"命令执行错误: {str(e)}"
            self.log(error_msg)
            return "", error_msg, 1
    
    def log(self, message):
        """添加消息到日志框"""
        self.log_text.insert(tk.END, message + "\n")
        self.log_text.see(tk.END)
        self.root.update_idletasks()
    
    def create_account(self):
        """创建新账户并配置私钥路径和活动链"""
        account_name = self.account_name_var.get().strip()
        if not account_name:
            messagebox.showerror("错误", "请输入账户名称")
            return

        def create_account_thread():
            try:
                self.status_var.set("正在创建账户...")

                # 交互输入：账户名 + 回车 + 再回车接受默认 ETH
                input_text = f"{account_name}\n\n"

                # 两种命令：先带 --key-format，再无参数
                cmd_withkey = [self.aleph_bat_path, "account", "create",
                            "--key-format", "hexadecimal"]
                cmd_plain   = [self.aleph_bat_path, "account", "create"]

                # ---------- 第 1 步：先带参数 ----------
                stdout, stderr, rc = self.run_command(cmd_withkey, input_text=input_text)

                # 如果带参数失败，则尝试无参数
                if rc != 0:
                    self.log(f"带 --key-format 参数失败，错误信息: {stderr.strip()}，改为无参数重试")
                    stdout, stderr, rc = self.run_command(cmd_plain, input_text=input_text)

                # ---------- 最终结果处理 ----------
                if rc != 0:
                    self.log(f"创建账户失败: {stderr.strip()}")
                    self.root.after(0, lambda: self.status_var.set("账户创建失败"))
                    return

                if "is now your default configuration" in stdout:
                    self.log("账户创建并配置成功")
                    self.root.after(0, lambda: self.status_var.set("账户创建并配置成功"))
                else:
                    self.log("账户创建成功，但配置可能不完整")
                    self.root.after(0, lambda: self.status_var.set("账户创建成功，但可能需要手动配置"))

                # 刷新账户列表
                self.root.after(1000, self.refresh_accounts)

            except Exception as e:
                self.log(f"创建账户时出错: {e}")
                self.root.after(0, lambda: self.status_var.set("创建账户出错"))

        thread = threading.Thread(target=create_account_thread)
        thread.daemon = True
        thread.start()

    
    def refresh_accounts(self):
        def refresh_thread():
            try:
                self.status_var.set("正在刷新账户列表...")
                # 创建startupinfo对象，用于隐藏命令行窗口（仅适用于Windows）
                startupinfo = None
                if sys.platform == "win32":
                    startupinfo = subprocess.STARTUPINFO()
                    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                    startupinfo.wShowWindow = subprocess.SW_HIDE
                
                command = [self.aleph_bat_path, "account", "list"]
                stdout, stderr, returncode = self.run_command(command)
                
                if returncode == 0 and stdout:
                    accounts = []
                    active_account = None
                    account_indices = {}  # {name: index_in_table}
                    unlinked_indices = {}  # {name: index_in_unlinked_list}

                    current_index = 0
                    unlinked_index = 1  # 可用私钥列表从 1 开始

                    for line in stdout.splitlines():
                        match = re.search(r'[│|]\s+(\w+)\s+[│|].*[│|]\s+(\*|-)\s*[│|]', line)
                        if match:
                            name = match.group(1)
                            is_active = match.group(2) == '*'
                            accounts.append(name)
                            account_indices[name] = current_index + 1  # 表格索引从 1 开始
                            if is_active:
                                active_account = name
                            else:
                                unlinked_indices[name] = unlinked_index
                                unlinked_index += 1
                            current_index += 1

                    if accounts:
                        self.root.after(0, lambda: self.update_account_list(accounts, active_account, account_indices, unlinked_indices))
                        self.root.after(0, lambda: self.status_var.set("账户列表刷新成功"))
                    else:
                        self.root.after(0, lambda: self.status_var.set("未找到任何账户，请先创建一个账户"))
                        self.root.after(0, lambda: messagebox.showinfo("提示", "你还没有账户，请先创建一个账户吧"))
                else:
                    self.log(f"刷新账户列表失败: {stderr}")
                    self.root.after(0, lambda: self.status_var.set("账户列表刷新失败"))
                    self.root.after(0, lambda: messagebox.showerror("错误", f"无法获取账户列表：{stderr}"))

            except Exception as e:
                self.log(f"刷新账户列表失败: {str(e)}")
                self.root.after(0, lambda: self.status_var.set("刷新账户列表出错"))
                self.root.after(0, lambda: messagebox.showerror("错误", f"刷新账户列表时出错: {str(e)}"))

        thread = threading.Thread(target=refresh_thread)
        thread.daemon = True
        thread.start()
    
    def update_account_list(self, accounts, active_account, account_indices, unlinked_indices):
        self.account_combo['values'] = accounts
        self.account_indices = account_indices  # 表格中的索引
        self.unlinked_indices = unlinked_indices  # 可用私钥列表中的索引
        if accounts:
            if active_account in accounts:
                self.account_combo.set(active_account)
            else:
                self.account_combo.set(accounts[0])
        
    def switch_account(self):
        account_name = self.account_list_var.get()
        if not account_name:
            messagebox.showerror("错误", "请选择一个账户")
            return

        def switch_account_thread():
            try:
                self.status_var.set(f"正在切换到账户: {account_name}...")
                
                # 首先获取当前活动账户和可用账户列表
                command = [self.aleph_bat_path, "account", "list"]
                stdout, stderr, returncode = self.run_command(command)
                
                if returncode != 0:
                    self.log(f"获取账户列表失败: {stderr}")
                    self.root.after(0, lambda: self.status_var.set("切换账户失败：无法获取账户列表"))
                    return
                    
                # 分析输出，找出目标账户的索引
                target_index = None
                account_lines = stdout.strip().split('\n')
                
                # 查找包含未链接私钥列表行的开始（通常在"Available unlinked private keys:"后面）
                for i, line in enumerate(account_lines):
                    if account_name in line:
                        # 提取前面的索引号，假设格式是 "│ account_name │ path │ - │"
                        # 或者在配置过程中是 "[index] path"
                        match = re.search(r'\[(\d+)\].*{}'.format(account_name), line)
                        if match:
                            target_index = match.group(1)
                            break
                
                if not target_index:
                    # 如果在上面的循环中找不到，就使用简单的方法：
                    # cenglin123 是列表中的第一个非活动账户，所以索引是1
                    # cenglin1232 是第二个，所以索引是2，依此类推
                    active_count = 0
                    for line in account_lines:
                        if ' - ' in line and account_name in line:
                            active_count += 1
                            target_index = str(active_count)
                            break
                        elif ' - ' in line:
                            active_count += 1
                
                if not target_index:
                    self.log(f"无法确定账户 {account_name} 的索引，尝试使用默认索引")
                    # 最后的尝试，假设索引值
                    if account_name == "cenglin123":
                        target_index = "1"
                    elif account_name == "cenglin1232":
                        target_index = "2"
                    else:
                        # 构建一个可能的索引映射
                        accounts_list = list(self.account_combo['values'])
                        try:
                            # 找出当前激活的账户在列表中的位置
                            active_account = None
                            for line in account_lines:
                                if ' * ' in line:
                                    for acc in accounts_list:
                                        if acc in line:
                                            active_account = acc
                                            break
                            
                            # 计算目标账户的相对位置
                            if active_account:
                                active_idx = accounts_list.index(active_account)
                                target_idx = accounts_list.index(account_name)
                                # 如果目标在激活账户之后，索引需要减1
                                if target_idx > active_idx:
                                    target_index = str(target_idx - active_idx)
                                else:
                                    target_index = str(target_idx + 1)
                            else:
                                # 如果找不到激活账户，就用账户在列表中的位置+1
                                target_index = str(accounts_list.index(account_name) + 1)
                        except Exception as e:
                            self.log(f"计算索引失败: {str(e)}")
                            target_index = "1"  # 默认尝试第一个
                
                self.log(f"使用索引 {target_index} 切换到账户 {account_name}")
                
                # 运行配置命令
                command = [self.aleph_bat_path, "account", "config"]
                # 构建输入序列：n（不保留当前私钥）+ 索引号 + 回车（接受默认链）
                input_text = f"n\n{target_index}\n\n"
                
                stdout, stderr, returncode = self.run_command(command, input_text=input_text)
                
                if returncode == 0 and "New Default Configuration" in stdout:
                    self.log(f"成功切换到账户: {account_name}")
                    self.root.after(0, lambda: self.status_var.set(f"成功切换到账户: {account_name}"))
                    self.root.after(1000, self.refresh_accounts)
                else:
                    if "Invalid file index" in stderr or stderr.strip() == "":
                        # 尝试备用方法：直接指定私钥路径
                        self.log("索引无效，尝试直接指定私钥路径")
                        
                        wsl_username = self.get_wsl_username()
                        key_path = f"/home/{wsl_username}/.aleph-im/private-keys/{account_name}.key"
                        
                        command = [self.aleph_bat_path, "account", "config", key_path, "ETH"]
                        stdout, stderr, returncode = self.run_command(command)
                        
                        if returncode == 0:
                            self.log(f"成功切换到账户: {account_name}")
                            self.root.after(0, lambda: self.status_var.set(f"成功切换到账户: {account_name}"))
                            self.root.after(1000, self.refresh_accounts)
                        else:
                            self.log(f"所有切换方法都失败: {stderr}")
                            self.root.after(0, lambda: self.status_var.set(f"切换账户失败"))
                    else:
                        self.log(f"切换失败: {stderr}")
                        self.root.after(0, lambda: self.status_var.set(f"切换账户失败"))
            
            except Exception as e:
                self.log(f"切换账户时出错: {str(e)}")
                self.root.after(0, lambda: self.status_var.set("切换账户出错"))

        thread = threading.Thread(target=switch_account_thread)
        thread.daemon = True
        thread.start()

    def find_account_index(self, output, account_name):
        """从账户列表输出中查找账户名对应的索引"""
        lines = output.splitlines()
        for i, line in enumerate(lines):
            if account_name in line and "/private-keys/" in line:
                # 假设账户行包含账户名和私钥路径
                # 实际逻辑需根据 aleph account list 的输出格式调整
                return i + 1  # 假设索引从1开始
        return None

    def find_account_index(self, output, account_name):
        """从账户列表输出中查找账户名对应的索引"""
        lines = output.splitlines()
        for i, line in enumerate(lines):
            if account_name in line and "/private-keys/" in line:
                # 假设账户行包含账户名和私钥路径
                # 实际逻辑需根据 aleph account list 的输出格式调整
                return i + 1  # 假设索引从1开始
        return None
    
    def delete_account(self):
        """删除选定的账户"""
        account_name = self.account_list_var.get()
        if not account_name:
            messagebox.showerror("错误", "请选择一个账户")
            return

        # 获取当前账户列表
        current_accounts = list(self.account_combo['values'])
        if len(current_accounts) <= 1:
            messagebox.showwarning("警告", "至少需要保留一个账户，无法删除最后一个账户。")
            return

        if not messagebox.askyesno("确认", f"确定要删除账户 {account_name} 吗?"):
            return

        def delete_account_thread():
            try:
                self.status_var.set(f"正在删除账户: {account_name}...")
                # 获取WSL用户名
                wsl_username = self.get_wsl_username()
                if not wsl_username:
                    self.log("无法获取WSL用户名")
                    self.root.after(0, lambda: self.status_var.set("删除账户失败：无法获取WSL用户名"))
                    return

                # 构建可能的账户路径
                path = f"/home/{wsl_username}/.aleph-im/private-keys/{account_name}.key"
                self.log(f"尝试删除文件: {path}")

                # 首先检查文件是否存在
                check_command = f"wsl test -f \"{path}\" && echo 'File exists' || echo 'File not found'"
                stdout, stderr, returncode = self.run_command(check_command)
                if "File exists" in stdout:
                    self.log("文件存在，尝试删除...")
                    # 使用强制删除选项
                    command = f"wsl rm -f \"{path}\""
                    stdout, stderr, returncode = self.run_command(command)

                    # 再次检查文件是否已删除
                    check_again = f"wsl test -f \"{path}\" && echo 'Still exists' || echo 'Deleted'"
                    stdout, stderr, returncode = self.run_command(check_again)
                    if "Deleted" in stdout:
                        self.log("文件已成功删除")
                        self.root.after(0, lambda: self.status_var.set(f"成功删除账户: {account_name}"))
                        # 延迟刷新以确保系统有时间处理删除
                        self.root.after(1000, self.refresh_accounts)
                    else:
                        self.log("文件删除后仍然存在，尝试使用sudo")
                        # 尝试使用 sudo 删除（可能需要密码）
                        command = f"wsl sudo rm -f \"{path}\""
                        stdout, stderr, returncode = self.run_command(command)
                        self.root.after(1000, self.refresh_accounts)
                else:
                    self.log(f"文件不存在: {path}")
                    # 尝试使用不同的文件名格式或路径
                    alt_path = f"/home/{wsl_username}/.aleph-im/private-keys/{account_name}.key"
                    self.log(f"尝试备用路径: {alt_path}")
                    command = f"wsl rm -f \"{alt_path}\""
                    self.run_command(command)
                    # 可能需要强制刷新 aleph 配置
                    command = [self.aleph_bat_path, "account", "config", account_name == "cenglin123" and "cenglin1231" or "cenglin123"]
                    self.run_command(command)
                    self.root.after(1000, self.refresh_accounts)
            except Exception as e:
                error_msg = f"删除账户时出错: {str(e)}"
                self.log(error_msg)
                self.root.after(0, lambda: self.status_var.set("删除账户出错"))

        thread = threading.Thread(target=delete_account_thread)
        thread.daemon = True
        thread.start()

    def get_wsl_username(self):
        """获取WSL用户名（优先使用 whoami，失败则尝试从 aleph.bat 中提取）"""
        try:
            # 方法1: 使用 whoami
            command = "wsl whoami"
            stdout, stderr, returncode = self.run_command(command)
            if returncode == 0 and stdout:
                username = stdout.strip().split('\\')[-1]
                self.log(f"WSL用户名: {username}")
                return username

            # 方法2: 从 aleph.bat 中提取
            if os.path.exists(self.aleph_bat_path):
                with open(self.aleph_bat_path, "r") as f:
                    content = f.read()
                    match = re.search(r'/home/(\w+)/', content)
                    if match:
                        username = match.group(1)
                        self.log(f"从 aleph.bat 获取到 WSL 用户名: {username}")
                        return username
            return "cenglin123"
        except Exception as e:
            self.log(f"获取 WSL 用户名时出错: {str(e)}")
            return "cenglin123"

    # 添加显示文件列表方法
    def show_file_list(self):
        """获取JSON格式的文件列表并在日志框中格式化显示"""
        def file_list_thread():
            try:
                self.status_var.set("正在获取文件列表...")
                self.log("正在获取文件列表...")
                
                # 分隔线，让日志更清晰
                self.log("-" * 80)
                self.log("【文件列表开始】")
                self.log("-" * 80)
                
                # 执行 aleph file list --json 命令获取JSON格式输出
                command = [self.aleph_bat_path, "file", "list", "--json"]
                stdout, stderr, returncode = self.run_command(command)
                
                if returncode == 0 and stdout:
                    try:
                        # 解析JSON数据
                        import json
                        data = json.loads(stdout)
                        
                        # 提取基本信息
                        address = data.get('address', 'Unknown')
                        # 将总大小从字节转换为MB并格式化
                        total_size_bytes = data.get('total_size', 0)
                        total_size_mb = total_size_bytes / (1024 * 1024)
                        pagination_page = data.get('pagination_page', 1)
                        pagination_total = data.get('pagination_total', 0)
                        pagination_per_page = data.get('pagination_per_page', 100)
                        
                        # 输出基本信息
                        self.log(f"Address: {address}")
                        self.log(f"Total Size: ~ {total_size_mb:.4f} MB")
                        self.log("Pagination:")
                        self.log(f"Page: {pagination_page}")
                        self.log(f"Total Item: {pagination_total}")
                        self.log(f"Items Max Per Page: {pagination_per_page}")
                        
                        # 输出表头
                        header = "Files Information"
                        self.log(f"{header:^100}")
                        
                        # 列标题
                        columns_header = "  File Hash                                          Size (MB)       Type   Created              Item Hash"
                        self.log(columns_header)
                        
                        # 分隔线
                        separator = " " + "━" * 81
                        self.log(separator)
                        
                        # 输出文件列表
                        files = data.get('files', [])
                        for file in files:
                            file_hash = file.get('file_hash', 'Unknown')
                            size_bytes = file.get('size', 0)
                            size_mb = size_bytes / (1024 * 1024)
                            file_type = file.get('type', 'Unknown')
                            created = file.get('created', 'Unknown')
                            item_hash = file.get('item_hash', 'Unknown')
                            
                            # 格式化创建时间 (从ISO格式截取到秒)
                            if created != 'Unknown':
                                try:
                                    # 只保留日期和时间部分，去掉微秒和时区
                                    created_parts = created.split('.')
                                    created_formatted = created_parts[0].replace('T', ' ')
                                except:
                                    created_formatted = created
                            else:
                                created_formatted = 'Unknown'
                            
                            # 格式化文件信息行
                            file_line = f"  {file_hash:<50} {size_mb:<10.4f} MB   {file_type:<5}  {created_formatted:<19}  {item_hash}"
                            self.log(file_line)
                        
                    except json.JSONDecodeError:
                        self.log("无法解析JSON数据，原始输出如下:")
                        self.log(stdout)
                    except Exception as e:
                        self.log(f"处理JSON数据时出错: {str(e)}")
                        self.log("原始输出如下:")
                        self.log(stdout)
                else:
                    error_msg = f"获取文件列表失败: {stderr}"
                    self.log(error_msg)
                
                self.log("-" * 80)
                self.log("【文件列表结束】")
                self.log("-" * 80)
                self.root.after(0, lambda: self.status_var.set("文件列表显示完成"))
            
            except Exception as e:
                error_msg = f"获取文件列表时出错: {str(e)}"
                self.log(error_msg)
                self.root.after(0, lambda: self.status_var.set("获取文件列表出错"))
        
        thread = threading.Thread(target=file_list_thread)
        thread.daemon = True
        thread.start()

    # 访问IPNS地址
    def get_ipfs_gateway_port(self):
        """
        动态获取 IPFS Gateway 端口
        """
        try:
            # 调用 ipfs config Addresses.Gateway 获取 Gateway 地址
            result = subprocess.run(
                ["ipfs", "config", "Addresses.Gateway"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            if result.returncode != 0:
                raise Exception(f"IPFS 配置读取失败: {result.stderr.strip()}")

            # 解析 Gateway 地址，提取端口号
            gateway_address = result.stdout.strip()
            if not gateway_address.startswith("/ip4/"):
                raise Exception("无效的 Gateway 地址格式")

            # 提取端口号
            port_part = gateway_address.split("/")[-1]
            if not port_part.isdigit():
                raise Exception("无法解析 Gateway 端口")

            return int(port_part)
        except FileNotFoundError:
            raise Exception("未找到 IPFS 命令，请确保 IPFS 已安装并可用")
        except Exception as e:
            raise Exception(f"获取 IPFS Gateway 端口失败: {e}")

    def open_gateway(self):
        """
        打开 IPFS Gateway 并访问指定的 IPNS 地址
        """
        ipns_hash = "k51qzi5uqu5djx3hvne57dwcotpc8h76o2ygrxh05kck11j6wnhvse8jrfzf2w"  # 示例 IPNS 地址

        try:
            # 动态获取 IPFS Gateway 端口
            ipfs_gateway_port = self.get_ipfs_gateway_port()

            # 拼接 URL
            # url = f"http://127.0.0.1:{ipfs_gateway_port}/ipns/{ipns_hash}" # 路径形式
            url = f"http://{ipns_hash}.ipns.localhost:{ipfs_gateway_port}" # 子域名形式

            # 尝试打开浏览器
            webbrowser.open(url)
            print(f"已在浏览器中打开: {url}")
        except Exception as e:
            # 错误处理
            print(f"无法打开浏览器: {e}")




    def convert_cid_v1_to_v0(self, cid_v1):
        """将 v1 格式的 CID 转换为 v0 格式"""
        try:
            self.log(f"尝试将 CID v1 转换为 v0: {cid_v1}")
            # 创建startupinfo对象，用于隐藏命令行窗口（仅适用于Windows）
            startupinfo = None
            if sys.platform == "win32":
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                startupinfo.wShowWindow = subprocess.SW_HIDE

            result = subprocess.run(
                ["ipfs", "cid", "format", "-v", "0", cid_v1],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
                timeout=10
            )
            converted_cid = result.stdout.strip()
            if not converted_cid.startswith("Qm"):
                self.log(f"转换后的 CID 无效: {converted_cid}")
                return None
            self.log(f"成功转换为 CID v0: {converted_cid}")
            return converted_cid
        except subprocess.CalledProcessError as e:
            error_output = e.stderr.strip()
            self.log(f"转换 CID 失败: {error_output}")
            if "daemon not running" in error_output:
                self.root.after(0, lambda: messagebox.showwarning(
                    "IPFS 未启动", "请先启动 IPFS 守护进程。转换 CID 失败：IPFS 未运行。"
                ))
            else:
                self.root.after(0, lambda: messagebox.showerror(
                    "转换失败", f"无法将 CID {cid_v1} 转换为 v0 格式：{error_output}"
                ))
            return None
        except FileNotFoundError:
            self.log("未找到 ipfs 命令")
            self.root.after(0, lambda: messagebox.showerror(
                "IPFS 未安装", "未找到 ipfs 命令，请安装 IPFS 并添加到系统路径。"
            ))
            return None
        except Exception as e:
            self.log(f"转换 CID 时发生异常: {str(e)}")
            self.root.after(0, lambda: messagebox.showerror(
                "错误", f"转换 CID 时出错: {str(e)}"
            ))
            return None    
    def paste_cid(self):
        """从剪贴板粘贴CID"""
        try:
            # 尝试多种方式获取剪贴板内容
            try:
                # 方法1: 使用tkinter的clipboard_get
                clipboard_content = self.root.clipboard_get()
            except:
                try:
                    # 方法2: 使用子进程调用系统剪贴板命令
                    # 创建startupinfo对象，用于隐藏命令行窗口（仅适用于Windows）
                    startupinfo = None
                    if sys.platform == "win32":
                        startupinfo = subprocess.STARTUPINFO()
                        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                        startupinfo.wShowWindow = subprocess.SW_HIDE
                        
                        # Windows系统使用powershell获取剪贴板内容
                        process = subprocess.Popen(['powershell.exe', 'Get-Clipboard'], 
                                                stdout=subprocess.PIPE, text=True,
                                                startupinfo=startupinfo)  # 添加startupinfo参数
                        clipboard_content, _ = process.communicate()
                    else:
                        # Linux/Mac系统
                        if os.system('which xclip > /dev/null') == 0:
                            process = subprocess.Popen(['xclip', '-o', '-selection', 'clipboard'], 
                                                    stdout=subprocess.PIPE, text=True)
                            clipboard_content, _ = process.communicate()
                        else:
                            raise Exception("无法找到剪贴板工具")
                except:
                    # 如果上述方法都失败，显示错误
                    raise Exception("无法获取剪贴板内容")
                    
            # 如果成功获取剪贴板内容
            current_content = self.cid_text.get("1.0", tk.END).strip()
            
            # 确保剪贴板内容不为空
            if clipboard_content.strip():
                # 如果当前内容不为空，则在新行添加剪贴板内容
                if current_content:
                    # 确保以换行符结尾
                    if not current_content.endswith("\n"):
                        self.cid_text.insert(tk.END, "\n")
                    self.cid_text.insert(tk.END, clipboard_content.strip())
                else:
                    self.cid_text.insert("1.0", clipboard_content.strip())
                self.log(f"已粘贴剪贴板内容: {clipboard_content.strip()[:30]}...")
            else:
                self.log("剪贴板内容为空")
                messagebox.showinfo("提示", "剪贴板内容为空")
        except Exception as e:
            error_msg = f"无法从剪贴板获取内容: {str(e)}"
            self.log(error_msg)
            messagebox.showerror("错误", error_msg)

    def clear_cid(self):
        """清空CID输入框"""
        self.cid_text.delete("1.0", tk.END)    
    def pin_cid(self):
        cid_content = self.cid_text.get("1.0", tk.END).strip()
        if not cid_content:
            messagebox.showerror("错误", "请输入至少一个 CID")
            return
        cids = [cid.strip() for cid in cid_content.split("\n") if cid.strip()]
        if not cids:
            messagebox.showerror("错误", "请输入至少一个 CID")
            return

        # 检查是否为 v0 或 v1 格式
        invalid_cids = [cid for cid in cids if not (cid.startswith("Qm") or cid.startswith("bafy"))]
        if invalid_cids:
            messagebox.showerror("错误", f"以下 CID 既不是 v0 格式（Qm 开头）也不是可转换的 v1 格式（bafy 开头）:\n{', '.join(invalid_cids)}")
            return

        total_cids = len(cids)
        self.log(f"准备 Pin {total_cids} 个 CID，将依次执行，间隔 1 秒")
        
        # 创建一个列表来跟踪成功的CID
        successful_cids = []

        def pin_cids_thread():
            try:
                for i, cid in enumerate(cids):
                    self.status_var.set(f"正在 Pin CID ({i+1}/{total_cids}): {cid}...")
                    self.log(f"开始 Pin CID ({i+1}/{total_cids}): {cid}")
                    
                    original_cid = cid
                    # 转换 v1 CID
                    if cid.startswith("bafy"):
                        converted_cid = self.convert_cid_v1_to_v0(cid)
                        if not converted_cid:
                            continue  # 转换失败，跳过
                        cid = converted_cid

                    # 执行 Pin 操作
                    command = [self.aleph_bat_path, "file", "pin", cid]
                    stdout, stderr, returncode = self.run_command(command)
                    if returncode == 0:
                        success_msg = f"成功 Pin CID ({i+1}/{total_cids}): {cid}"
                        self.log(success_msg)
                        # 添加到成功列表中（使用原始输入的CID，而不是转换后的）
                        successful_cids.append(original_cid)
                    else:
                        error_msg = f"Pin CID ({i+1}/{total_cids}) 失败: {cid} - {stderr}"
                        self.log(error_msg)

                    # 等待 1 秒
                    if i < total_cids - 1:
                        self.log("等待 1 秒后继续...")
                        time.sleep(1)

                # 完成所有操作后，从文本框中移除成功的CID
                self.root.after(0, lambda: self.remove_successful_cids(successful_cids))
                
                final_msg = f"完成所有 {total_cids} 个 CID 的 Pin 操作，成功: {len(successful_cids)}"
                self.log(final_msg)
                self.root.after(0, lambda: self.status_var.set(final_msg))
            except Exception as e:
                error_msg = f"Pin CID 操作出错: {str(e)}"
                self.log(error_msg)
                self.root.after(0, lambda: self.status_var.set("Pin CID 出错"))

        thread = threading.Thread(target=pin_cids_thread)
        thread.daemon = True
        thread.start()

    def remove_successful_cids(self, successful_cids):
        """从文本框中移除成功Pin的CID"""
        if not successful_cids:
            return
            
        # 获取当前文本框内容
        current_content = self.cid_text.get("1.0", tk.END).strip()
        if not current_content:
            return
            
        # 分割成行
        lines = current_content.split("\n")
        
        # 过滤掉成功的CID
        remaining_lines = [line for line in lines if line.strip() not in successful_cids]
        
        # 更新文本框
        self.cid_text.delete("1.0", tk.END)
        if remaining_lines:
            self.cid_text.insert("1.0", "\n".join(remaining_lines))
            
        # 记录日志
        self.log(f"已从文本框移除 {len(successful_cids)} 个成功Pin的CID")

    def delete_cid(self):
        """删除CID对应的文件，处理一个CID对应多个item_hash的情况，支持CID v1转换"""
        # 获取用户输入的CID或item_hash
        input_content = self.cid_text.get("1.0", tk.END).strip()
        if not input_content:
            messagebox.showerror("错误", "请输入至少一个CID或item_hash")
            return
        
        # 分割多行输入，支持同时删除多个CID/item_hash
        input_items = [item.strip() for item in input_content.split("\n") if item.strip()]
        if not input_items:
            messagebox.showerror("错误", "请输入至少一个CID或item_hash")
            return
        
        # 确认删除
        if not messagebox.askyesno("确认", f"确定要删除以下{len(input_items)}个CID/item_hash吗?\n{', '.join(input_items[:3])}{'...' if len(input_items) > 3 else ''}"):
            return
        
        # 创建一个列表来跟踪成功删除的项目
        successful_items = []
        
        def delete_cid_thread():
            total_items = len(input_items)
            successful = 0
            failed = 0
            
            try:
                self.status_var.set(f"正在获取文件列表...")
                self.log(f"正在获取文件列表以准备删除{len(input_items)}个CID/item_hash")
                
                # 获取文件列表
                command = [self.aleph_bat_path, "file", "list", "--json"]
                stdout, stderr, returncode = self.run_command(command)
                
                if returncode != 0 or not stdout:
                    error_msg = f"获取文件列表失败: {stderr}"
                    self.log(error_msg)
                    self.root.after(0, lambda: self.status_var.set("删除CID失败：无法获取文件列表"))
                    self.root.after(0, lambda: messagebox.showerror("错误", error_msg))
                    return
                
                try:
                    # 解析JSON数据
                    import json
                    data = json.loads(stdout)
                    files = data.get('files', [])
                    
                    # 创建映射：CID -> 多个item_hash
                    # 使用字典的值为列表，存储一个CID对应的所有item_hash和文件信息
                    cid_to_items = {}
                    item_hash_to_info = {}
                    
                    for file in files:
                        file_hash = file.get('file_hash')
                        item_hash = file.get('item_hash')
                        file_type = file.get('type', 'Unknown')
                        file_size = file.get('size', 0)
                        file_created = file.get('created', 'Unknown')
                        
                        if file_hash and item_hash:
                            # 格式化创建时间
                            if file_created != 'Unknown':
                                try:
                                    created_parts = file_created.split('.')
                                    created_formatted = created_parts[0].replace('T', ' ')
                                except:
                                    created_formatted = file_created
                            else:
                                created_formatted = 'Unknown'
                            
                            # 格式化文件大小
                            if file_size:
                                size_mb = file_size / (1024 * 1024)
                                size_formatted = f"{size_mb:.4f} MB"
                            else:
                                size_formatted = "Unknown"
                            
                            # 存储文件信息
                            file_info = {
                                'item_hash': item_hash,
                                'file_hash': file_hash,
                                'type': file_type,
                                'size': size_formatted,
                                'created': created_formatted
                            }
                            
                            # 添加到CID映射表
                            if file_hash not in cid_to_items:
                                cid_to_items[file_hash] = []
                            cid_to_items[file_hash].append(file_info)
                            
                            # 添加到item_hash映射表
                            item_hash_to_info[item_hash] = file_info
                    
                    # 预先转换所有输入的CID v1为v0格式
                    converted_inputs = {}
                    for input_item in input_items:
                        if len(input_item) >= 59 and input_item.startswith("bafy"):  # 可能是CID v1
                            try:
                                # 尝试转换
                                self.log(f"尝试将可能的CID v1转换为v0: {input_item}")
                                converted_cid = self.convert_cid_v1_to_v0(input_item)
                                if converted_cid:
                                    self.log(f"成功将CID v1转换为v0: {input_item} -> {converted_cid}")
                                    converted_inputs[input_item] = converted_cid
                            except Exception as e:
                                self.log(f"转换CID v1失败: {input_item}, 错误: {str(e)}")
                                # 继续处理，不影响其他输入
                    
                    # 处理每个输入
                    for i, input_item in enumerate(input_items):
                        self.status_var.set(f"处理第 {i+1}/{total_items} 个...")
                        self.log(f"正在处理第 {i+1}/{total_items} 个: {input_item}")
                        
                        # 判断输入类型和查找匹配项
                        input_len = len(input_item)
                        items_to_delete = []
                        
                        # 先检查是否为CID v1格式且已转换
                        if input_item in converted_inputs:
                            converted_cid = converted_inputs[input_item]
                            if converted_cid in cid_to_items:
                                items_to_delete = cid_to_items[converted_cid]
                                self.log(f"CID v1已转换: {input_item} -> {converted_cid}, 匹配到 {len(items_to_delete)} 个item")
                            else:
                                self.log(f"CID v1已转换但在文件列表中未找到匹配: {input_item} -> {converted_cid}")
                                failed += 1
                                continue
                        
                        # 如果不是已转换的CID v1，按正常流程处理
                        elif input_len == 64:  # 看起来是item_hash (64字符长)
                            if input_item in item_hash_to_info:
                                items_to_delete = [item_hash_to_info[input_item]]
                                self.log(f"识别为item_hash: {input_item}")
                            else:
                                self.log(f"输入看起来像item_hash, 但在当前文件列表中未找到匹配: {input_item}")
                                failed += 1
                                continue
                        
                        elif input_len == 46 and input_item.startswith("Qm"):  # CID v0 (46字符，以Qm开头)
                            if input_item in cid_to_items:
                                items_to_delete = cid_to_items[input_item]
                                self.log(f"CID v0: {input_item} 匹配到 {len(items_to_delete)} 个item")
                            else:
                                self.log(f"CID v0在当前文件列表中未找到: {input_item}")
                                failed += 1
                                continue
                        
                        elif (input_len >= 55 and input_len <= 63) and input_item.startswith("b"):  # 未预处理的CID v1 (可能被截断或格式不完全正确)
                            # 再次尝试转换为v0格式
                            try:
                                converted_cid = self.convert_cid_v1_to_v0(input_item)
                                if converted_cid and converted_cid in cid_to_items:
                                    items_to_delete = cid_to_items[converted_cid]
                                    self.log(f"CID v1(再次尝试): {input_item} -> CID v0: {converted_cid} 匹配到 {len(items_to_delete)} 个item")
                                else:
                                    self.log(f"CID v1转换失败或在文件列表中未找到: {input_item}")
                                    failed += 1
                                    continue
                            except Exception as e:
                                self.log(f"处理可能的CID v1时出错: {input_item}, 错误: {str(e)}")
                                failed += 1
                                continue
                        
                        else:  # 其他格式
                            # 尝试直接在CID映射中查找
                            if input_item in cid_to_items:
                                items_to_delete = cid_to_items[input_item]
                                self.log(f"CID: {input_item} 匹配到 {len(items_to_delete)} 个item")
                            else:
                                self.log(f"无法识别的输入格式或在文件列表中未找到: {input_item}")
                                failed += 1
                                continue
                        
                        # 处理找到的匹配项
                        if items_to_delete:
                            # 如果只有一个匹配项，直接删除
                            if len(items_to_delete) == 1:
                                item_info = items_to_delete[0]
                                item_hash_to_delete = item_info['item_hash']
                                self.log(f"找到单个匹配项，正在删除 item_hash: {item_hash_to_delete}")
                                
                                delete_command = [self.aleph_bat_path, "file", "forget", item_hash_to_delete]
                                delete_stdout, delete_stderr, delete_returncode = self.run_command(delete_command)
                                
                                if delete_returncode == 0:
                                    self.log(f"成功删除: {input_item} -> {item_hash_to_delete}")
                                    successful += 1
                                    # 添加到成功列表
                                    successful_items.append(input_item)
                                else:
                                    self.log(f"删除失败: {input_item} -> {item_hash_to_delete}, 错误: {delete_stderr}")
                                    failed += 1
                            
                            # 如果有多个匹配项，让用户选择
                            else:
                                # 构建选择对话框内容
                                file_info_list = []
                                for idx, item_info in enumerate(items_to_delete):
                                    file_info = f"{idx+1}. Hash: {item_info['file_hash'][:10]}...{item_info['file_hash'][-6:]}\n   Type: {item_info['type']}, Size: {item_info['size']}, Created: {item_info['created']}\n   Item Hash: {item_info['item_hash'][:10]}...{item_info['item_hash'][-6:]}"
                                    file_info_list.append(file_info)
                                
                                # 在主线程中显示选择对话框
                                selection_result = [None]  # 使用列表存储选择结果，以便在线程间传递
                                
                                def show_selection_dialog():
                                    from tkinter import simpledialog
                                    
                                    # 创建自定义对话框类，以便设置图标
                                    class CustomDialog(simpledialog.Dialog):
                                        def __init__(self, parent, title, prompt, icon_path=None):
                                            self.prompt = prompt
                                            self.icon_path = icon_path
                                            super().__init__(parent, title)
                                            
                                        def body(self, master):
                                            # 设置对话框图标
                                            if self.icon_path and os.path.exists(self.icon_path):
                                                try:
                                                    self.tk.call('wm', 'iconbitmap', self, self.icon_path)
                                                except:
                                                    pass  # 忽略设置图标错误
                                    
                                            # 添加提示标签
                                            tk.Label(master, text=self.prompt, wraplength=550, justify=tk.LEFT).pack(pady=10, padx=10)
                                            
                                            # 创建输入框
                                            self.entry = tk.Entry(master, width=10)
                                            self.entry.pack(pady=10, padx=10)
                                            self.entry.focus_set()
                                            
                                            return self.entry  # 初始焦点
                                        
                                        def apply(self):
                                            self.result = self.entry.get()
                                    
                                    # 构建描述文本
                                    description = f"为CID: {input_item} 找到多个匹配项，请选择要删除的号码(1-{len(items_to_delete)})，输入'all'删除全部，或'cancel'取消:"
                                    details = "\n\n".join(file_info_list)
                                    full_prompt = f"{description}\n\n{details}"
                                    
                                    # 显示自定义对话框
                                    dialog = CustomDialog(self.root, "选择要删除的文件", full_prompt, self.icon_path)
                                    selection_result[0] = dialog.result if dialog.result else "cancel"
                                
                                # 在主线程中显示对话框
                                self.root.after(0, show_selection_dialog)
                                
                                # 等待用户选择
                                while selection_result[0] is None:
                                    time.sleep(0.1)
                                
                                selection = selection_result[0]
                                
                                # 处理用户选择
                                if selection is None or selection.lower() == 'cancel':
                                    self.log(f"用户取消了删除: {input_item}")
                                    failed += 1
                                    continue
                                
                                # 删除所有
                                elif selection.lower() == 'all':
                                    self.log(f"用户选择删除CID: {input_item} 的所有 {len(items_to_delete)} 个匹配项")
                                    all_successful = True
                                    
                                    for item_info in items_to_delete:
                                        item_hash_to_delete = item_info['item_hash']
                                        self.log(f"正在删除 item_hash: {item_hash_to_delete}")
                                        
                                        delete_command = [self.aleph_bat_path, "file", "forget", item_hash_to_delete]
                                        delete_stdout, delete_stderr, delete_returncode = self.run_command(delete_command)
                                        
                                        if delete_returncode == 0:
                                            self.log(f"成功删除 item_hash: {item_hash_to_delete}")
                                        else:
                                            self.log(f"删除失败 item_hash: {item_hash_to_delete}, 错误: {delete_stderr}")
                                            all_successful = False
                                    
                                    if all_successful:
                                        self.log(f"成功删除CID: {input_item} 的所有匹配项")
                                        successful += 1
                                        # 添加到成功列表
                                        successful_items.append(input_item)
                                    else:
                                        self.log(f"删除CID: {input_item} 的部分匹配项失败")
                                        failed += 1
                                
                                # 删除指定序号
                                else:
                                    try:
                                        idx = int(selection) - 1
                                        if 0 <= idx < len(items_to_delete):
                                            item_info = items_to_delete[idx]
                                            item_hash_to_delete = item_info['item_hash']
                                            self.log(f"用户选择删除序号 {idx+1}, item_hash: {item_hash_to_delete}")
                                            
                                            delete_command = [self.aleph_bat_path, "file", "forget", item_hash_to_delete]
                                            delete_stdout, delete_stderr, delete_returncode = self.run_command(delete_command)
                                            
                                            if delete_returncode == 0:
                                                self.log(f"成功删除: {input_item} -> {item_hash_to_delete}")
                                                successful += 1
                                                # 添加到成功列表
                                                successful_items.append(input_item)
                                            else:
                                                self.log(f"删除失败: {input_item} -> {item_hash_to_delete}, 错误: {delete_stderr}")
                                                failed += 1
                                        else:
                                            self.log(f"用户输入的序号无效: {selection}")
                                            failed += 1
                                    except ValueError:
                                        self.log(f"用户输入无效: {selection}")
                                        failed += 1
                        
                    # 从文本框中移除成功删除的项
                    self.root.after(0, lambda: self.remove_successfully_deleted_items(successful_items))
                    
                    # 总结
                    self.log(f"删除操作完成: 成功 {successful}, 失败 {failed}, 总计 {total_items}")
                    summary_msg = f"删除完成: 成功 {successful}, 失败 {failed}, 总计 {total_items}"
                    self.root.after(0, lambda: self.status_var.set(summary_msg))
                    
                    # 如果有失败的项目，显示警告
                    if failed > 0:
                        self.root.after(0, lambda: messagebox.showwarning("删除结果", summary_msg))
                    else:
                        self.root.after(0, lambda: messagebox.showinfo("删除结果", summary_msg))
                    
                except json.JSONDecodeError as e:
                    error_msg = f"解析文件列表JSON数据失败: {str(e)}"
                    self.log(error_msg)
                    self.root.after(0, lambda: self.status_var.set("删除CID失败：无法解析文件列表"))
                    self.root.after(0, lambda: messagebox.showerror("错误", error_msg))
                
                except Exception as e:
                    error_msg = f"处理文件列表数据时出错: {str(e)}"
                    self.log(error_msg)
                    self.root.after(0, lambda: self.status_var.set("删除CID失败：处理数据出错"))
                    self.root.after(0, lambda: messagebox.showerror("错误", error_msg))
            
            except Exception as e:
                error_msg = f"删除CID过程中出现错误: {str(e)}"
                self.log(error_msg)
                self.root.after(0, lambda: self.status_var.set("删除CID出错"))
                self.root.after(0, lambda: messagebox.showerror("错误", error_msg))
        
        # 启动线程执行删除操作
        thread = threading.Thread(target=delete_cid_thread)
        thread.daemon = True
        thread.start()

    def remove_successfully_deleted_items(self, successful_items):
        """从文本框中移除成功删除的CID或item_hash"""
        if not successful_items:
            return
            
        # 获取当前文本框内容
        current_content = self.cid_text.get("1.0", tk.END).strip()
        if not current_content:
            return
            
        # 分割成行
        lines = current_content.split("\n")
        
        # 过滤掉成功删除的项目
        remaining_lines = [line for line in lines if line.strip() not in successful_items]
        
        # 更新文本框
        self.cid_text.delete("1.0", tk.END)
        if remaining_lines:
            self.cid_text.insert("1.0", "\n".join(remaining_lines))
            
        # 记录日志
        self.log(f"已从文本框移除 {len(successful_items)} 个成功删除的项目")

def main():
    root = tk.Tk()
    
    # 先构建 aleph_bat_path 路径
    aleph_bat_path = os.path.join(application_path, "tools", "aleph.bat")

    # 检查 aleph.bat 是否存在
    if not os.path.exists(aleph_bat_path):
        messagebox.showerror(
            "错误",
            "在 tools 目录下找不到 aleph.bat 文件！\n\n"
            "请先执行 aleph_init.bat 文件进行初始化。\n"
            "并确保 aleph.bat 文件在本程序目录下的 tools 文件夹中。"
        )
        return
    
    # 创建应用程序实例
    app = AlephManager(root)
    
    # 启动主循环
    try:
        root.mainloop()
    except Exception as e:
        messagebox.showerror("错误", f"程序运行时出错: {str(e)}")

if __name__ == "__main__":
    main()