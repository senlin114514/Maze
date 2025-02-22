import os
import sys
import json
import hashlib
import threading
import platform
import requests
import zipfile
import shutil
import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime, timedelta
from pathlib import Path
from subprocess import Popen
from urllib.parse import quote


def get_platform():
    sys_platform = platform.system().lower()
    if sys_platform == "darwin":
        return "\"mac\""
    elif sys_platform == "windows":
        return "\"windows\""
    elif sys_platform == "linux":
        return "linux"
    return "unknown"

def get_cache_dir():
    system = get_platform()
    if system == "windows":
        return Path(os.getenv('LOCALAPPDATA')) / "Maze"
    elif system == "mac":
        return Path.home() / "Library" / "Caches" / "Maze"
    else:  # linux
        return Path.home() / ".cache" / "Maze"

class DownloaderGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Maze Launcher")
        
        # macOS特定配置
        if platform.system() == "Darwin":
            self.root.createcommand('tk::mac::ReopenApplication', self.root.lift)
        
        self.progress_var = tk.DoubleVar()
        self.status_var = tk.StringVar()
        self.size_var = tk.StringVar()
        self.time_var = tk.StringVar()
        
        # 设置窗口大小和位置
        window_width = 400
        window_height = 200
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = (screen_width - window_width) // 2
        y = (screen_height - window_height) // 2
        self.root.geometry(f"{window_width}x{window_height}+{x}+{y}")
        
        # 主框架
        self.frame = ttk.Frame(self.root)
        self.frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # 标题
        title_label = ttk.Label(
            self.frame, 
            text="正在下载游戏文件", 
            font=("SF Pro", 14, "bold")  # macOS默认字体
        )
        title_label.pack(pady=(0, 10))
        
        # 进度条
        self.progress_bar = ttk.Progressbar(
            self.frame,
            variable=self.progress_var,
            maximum=100,
            length=350,
            mode='determinate'
        )
        self.progress_bar.pack(pady=5, fill=tk.X)
        
        # 信息框架
        info_frame = ttk.Frame(self.frame)
        info_frame.pack(fill=tk.X, pady=5)
        
        # 下载大小信息
        size_label = ttk.Label(info_frame, textvariable=self.size_var)
        size_label.pack(anchor=tk.W)
        
        # 速度信息
        speed_label = ttk.Label(info_frame, textvariable=self.status_var)
        speed_label.pack(anchor=tk.W)
        
        # 剩余时间信息
        time_label = ttk.Label(info_frame, textvariable=self.time_var)
        time_label.pack(anchor=tk.W)
        
        # 取消按钮
        self.cancel_btn = ttk.Button(
            self.frame,
            text="取消下载",
            command=self.on_cancel,
            width=20
        )
        self.cancel_btn.pack(pady=(10, 0))
        
        self.downloading = True
        self.cancelled = False
        
        # 确保窗口显示在最前面
        self.root.lift()
        self.root.attributes('-topmost', True)
        self.root.after_idle(self.root.attributes, '-topmost', False)

    def format_size(self, size_bytes):
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.1f} GB"

    def format_time(self, seconds):
        if seconds < 60:
            return f"{seconds:.0f}秒"
        elif seconds < 3600:
            minutes = seconds / 60
            return f"{minutes:.0f}分钟"
        else:
            hours = seconds / 3600
            return f"{hours:.1f}小时"

    def update_progress(self, downloaded, total_size, speed):
        def update():
            percentage = (downloaded / total_size) * 100 if total_size > 0 else 0
            self.progress_var.set(percentage)
            
            # 更新大小信息
            size_text = f"已下载: {self.format_size(downloaded)} / {self.format_size(total_size)}"
            self.size_var.set(size_text)
            
            # 更新速度信息
            speed_text = f"下载速度: {self.format_size(speed)}/s"
            self.status_var.set(speed_text)
            
            # 更新剩余时间
            if speed > 0:
                remaining_seconds = (total_size - downloaded) / speed
                time_text = f"预计还需: {self.format_time(remaining_seconds)}"
                self.time_var.set(time_text)
        
        self.root.after(0, update)

    def on_cancel(self):
        self.cancelled = True
        self.root.destroy()

    def show(self):
        self.root.mainloop()

class MazeLauncher:
    def __init__(self):
        self.platform = get_platform()
        self.cache_dir = get_cache_dir()
        self.app_dir = self.cache_dir / "app"
        self.zip_path = self.cache_dir / "maze.zip"
        self.version_file = self.cache_dir / "version.json"
        self.base_url = "https://app.huajinet.link/"
        self.gui = None
        self.current_version = None

    def ensure_directory(self):
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.app_dir.mkdir(parents=True, exist_ok=True)

    def get_remote_info(self, check_update=False):
        url = self.base_url
        print(url)
        if not check_update:
            url += f"?platform={quote(self.platform)}"
            print(url)
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            messagebox.showerror("错误", f"无法获取版本信息: {str(e)}")
        return None

    def verify_hash(self, file_path, expected_hash):
        if not expected_hash:
            return True
            
        sha1 = hashlib.sha1()  # 改用SHA1
        with open(file_path, "rb") as f:
            while chunk := f.read(8192):  # 使用8KB的块大小
                sha1.update(chunk)
        return sha1.hexdigest() == expected_hash

    def download_file(self, url, dest_path, expected_hash):
        print("开始下载文件")
        try:
            with requests.get(url, stream=True) as r:
                r.raise_for_status()
                total_size = int(r.headers.get('content-length', 0))
                downloaded = 0
                start_time = datetime.now()
                
                with open(dest_path, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            
                            # 计算速度和更新进度
                            time_diff = (datetime.now() - start_time).total_seconds()
                            speed = downloaded / (time_diff + 1e-6)  # bytes per second
                            
                            if self.gui:
                                self.gui.update_progress(downloaded, total_size, speed)
                            
                            if self.gui and self.gui.cancelled:
                                os.remove(dest_path)
                                return False
                
            return True
        except Exception as e:
            if Path(dest_path).exists():
                os.remove(dest_path)
            messagebox.showerror("错误", f"下载失败: {str(e)}")
            return False

    def extract_zip(self):
        try:
            # 清理旧的应用目录
            if self.app_dir.exists():
                shutil.rmtree(self.app_dir)
            self.app_dir.mkdir(parents=True, exist_ok=True)

            # 解压缩文件
            with zipfile.ZipFile(self.zip_path, 'r') as zip_ref:
                zip_ref.extractall(self.app_dir)
            
            # 删除zip文件
            os.remove(self.zip_path)
            return True
        except Exception as e:
            messagebox.showerror("错误", f"解压缩失败: {str(e)}")
            return False

    def find_executable(self):
        # 根据平台查找可执行文件
        if self.platform == "windows":
            exe_pattern = "*.exe"
        elif self.platform == "mac":
            exe_pattern = "*"  # macOS可执行文件可能没有特定后缀
        else:  # linux
            exe_pattern = "*"

        # 递归查找可执行文件
        for root, _, files in os.walk(self.app_dir):
            for file in files:
                if file.lower().endswith(exe_pattern.replace("*", "")):
                    path = Path(root) / file
                    if os.access(path, os.X_OK):  # 检查是否可执行
                        return path
        return None

    def create_version_file(self, version):
        data = {
            "time": datetime.now().isoformat(),
            "version": version
        }
        with open(self.version_file, 'w') as f:
            json.dump(data, f)

    def check_local_version(self):
        if not self.version_file.exists():
            return None
            
        try:
            with open(self.version_file) as f:
                data = json.load(f)
                return data.get("version")
        except:
            return None

    def needs_update(self, remote_info):
        # 情况4：缺少version.json或哈希不匹配
        if not self.version_file.exists():
            return True
            
        executable = self.find_executable()
        if not executable or not executable.exists():
            return True

        # 如果有hash值，验证文件完整性
        #if "hash" in remote_info:
        #    return not self.verify_hash(executable, remote_info["hash"])
        
        # 如果没有hash值，比较版本号
        local_version = self.check_local_version()
        return local_version != remote_info.get("version")

    def start_download(self, remote_info):
        self.gui = DownloaderGUI()
        download_thread = threading.Thread(
            target=self.perform_download,
            args=(remote_info,),
            daemon=True
        )
        download_thread.start()
        self.gui.show()
        download_thread.join()
        
        if self.app_dir.exists():
            self.create_version_file(remote_info["version"])
            self.launch_program()
        else:
            messagebox.showerror("错误", "下载未完成")

    def perform_download(self, remote_info):
        success = self.download_file(
            remote_info["downloadlink"],
            self.zip_path,
            remote_info.get("hash", "")
        )
        if success:
            success = self.extract_zip()
        
        if self.gui:
            self.gui.root.after(0, self.gui.root.destroy)
        
        if success:
            self.create_version_file(remote_info["version"])

    def launch_program(self):
        executable = self.find_executable()
        if not executable:
            messagebox.showerror("错误", "找不到可执行文件")
            return

        if self.platform == "windows":
            os.startfile(executable)
        else:
            Popen([str(executable)], start_new_session=True)

    def run(self):
        print(get_cache_dir())
        self.ensure_directory()
        print("application is running")
        print(self.get_remote_info())
        # 情况1：主程序不存在
        if not self.app_dir.exists():
            remote_info = self.get_remote_info()
            print(remote_info)
            if not remote_info:
                return
                
            if remote_info.get("status") != 200:
                messagebox.showerror("错误", "服务器返回错误")
                return
                
            self.start_download(remote_info)
            return

        # 情况2/3/4：检查更新
        remote_info = self.get_remote_info(check_update=False)  # Changed to get full info including download link
        if not remote_info:
            self.launch_program()
            return

        # 情况4：强制更新条件
        #if not self.version_file.exists() or \
        #   not self.verify_hash(self.zip_path, remote_info.get("hash", "")):
        #    self.start_download(remote_info)
        #    return

        # 比较版本
        if self.needs_update(remote_info):
            answer = messagebox.askyesno(
                "发现新版本",
                f"发现新版本 {remote_info['version']}，是否更新？",
                parent=self.gui.root if self.gui else None
            )
            if answer:
                self.start_download(remote_info)
            else:
                self.launch_program()
        else:
            self.launch_program()

if __name__ == "__main__":
    if platform.system() == "Darwin":
        os.environ['PYTHONUNBUFFERED'] = "1"
    launcher = MazeLauncher()
    launcher.run()