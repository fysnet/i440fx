<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>Bochs Emulator (USB Edition)</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
<link type="text/css" rel="stylesheet" href="bochsUSBed.css" />
</head>

<body>
<div id="content">
<div id="heading">
	<h1><a href="index.php">Bochs Emulator (USB Edition)</a></h1>
	<div id="partofdBochs"><a href="https://bochs.sourceforge.io/"><span>A fork of the Bochs Emulator</span></a></div>
	<div id="partofdfys"><a href="https://www.fysnet.net/osdesign_book_series.htm"><span>Part of the FYSOS Design Book Series</span></a></div>
	<ul id="navmenu">
		<li><a href="https://bochs.sourceforge.io/">Go to Official Bochs Emulator</a></li>
		<li><a href="index.php">Overview</a></li>
		<li><a href="documentation.php">Documentation</a></li>
		<li><a href="https://github.com/fysnet/Bochs-USB-Edition">Source Code</a></li>
		<li><a href="downloads.php">Downloads</a></li>
	</ul>
</div>

<div>
<p><strong>Bochs</strong> is a highly portable open-source IA-32 (x86) PC emulator written in C++, that runs on most popular platforms. It includes emulation of the Intel x86 CPU, common I/O devices, and a custom BIOS. Bochs can be compiled to emulate many different x86 CPUs, from early 386 to the most recent x86-64 Intel and AMD processors which may have not even reached the market yet.</p>
<p>Bochs is capable of running most Operating Systems inside the emulation including Linux, DOS, or Microsoft Windows. Bochs was originally written by Kevin Lawton and is currently maintained by people like you.</p>
<p>Bochs can be compiled and used in a variety of modes, some which are still in development. The 'typical' use of bochs is to provide complete x86 PC emulation, including the x86 processor, hardware devices, and memory. This allows you to run OS's and software within the emulator on your workstation, much like you have a machine inside of a machine. For instance, let's say your workstation is a Unix/X11 workstation, but you want to run Win'95 applications. Bochs will allow you to run Win 95 and associated software on your Unix/X11 workstation, displaying a window on your workstation, simulating a monitor on a PC.</p>
<p><strong>The Official Bochs website can be found at <a href="https://bochs.sourceforge.io/">https://bochs.sourceforge.io/</a></strong></p>

<div class="separator"></div>
<h2>Bochs -- USB Edition</h2>
<p>This page and all source code, documentation, and downloads mentioned here, is my <strong>Fork</strong><sup><a href="https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks">(ref)</a></sup> of the <a href="https://bochs.sourceforge.io/">Official Bochs project</a>.</p>
<p>My intent is to integrate enough function into the Bochs project to allow a user to research, develop, and debug their USB drivers. It includes support for the four major host controllers; UHCI, OHCI, EHCI, and xHCI, as well as USB devices such as a mouse, keyboard, thumb drive, floppy drive, or external hub.</p>
<p>My goal is to make it an elaborate form of USB driver debugging via emulation. You provide the bootable hard drive, and this edition of Bochs will allow you to monitor, test, and log USB function.</p>
</div>

<div class="separator"></div>

<h2>News</h2>
<p><strong>2025-Jan-25</strong> - <a href="https://bochs.sourceforge.io/">The Official Bochs Emulator</a> is now current with my code. As of now, this fork and the main tree should be identical.</p>
<p><strong>2025-Jan-25</strong> - I have included a <a href="https://github.com/fysnet/i440fx">new BIOS</a> that fixes a few issues with the Bochs BIOS and allows booting of USB devices.</p>
<p><strong>2023-Dec-10</strong> - The 'usb_debug' branch on the <a href="https://github.com/fysnet/Bochs-USB-Edition">Bochs-USB-Edition github</a> has now been updated with the new USB Debug files. These updates support the debugger on the xHCI and UHCI controllers. They are experimental, but I have put them through a few tests and all came out okay. The executables have not been updated yet, since the inclusion into the Bochs main source is imminent. Once this is included in the Bochs main tree, where others can test it as well, and testing is promising, I will update the executables. The <a href="documentation.php">Documentation</a> has been updated, see section 5.8.</p>
<p><strong>2023-Oct-23</strong> - The 'usb_debug' branch on the <a href="https://github.com/fysnet/Bochs-USB-Edition">Bochs-USB-Edition github</a> was inconsistent with the master branch so it needed to be updated. It has been indirectly expressed to me that the branch would not be merged into the main Bochs tree until the USB Debugger was complete. Well, that is going to be some time since there is still a lot of work that needs to be done. Since I don't wish to maintain a branch that won't be merged for some time, I am not going to have the branch available on the github site. <b>However</b>, as I continue to work on the USB Debugger, feel free to contact me at <i>fys [at] fysnet [dot] net</i> if you wish to receive a copy. I will be more than happy to send you the current code. I will try to keep the <a href="downloads.php">binaries</a> and <a href="documentation.php">Documentation</a> up to date.</p>
<p><strong>2023-Sept-18</strong> - The 'usb_debug' branch on the <a href="https://github.com/fysnet/Bochs-USB-Edition">Bochs-USB-Edition github</a> is now up to date with my current work, and will have periodical updates to add more features.</p>
<p><strong>2023-Sept-02</strong> - Regression state.<br />Per request and as to commit small pull requests, I have regressed this fork back to the current Bochs state and will add small pull requests to bring the USB part of Bochs current to my additions.</p>
<p><strong>2023-May-31</strong> - Summer release (first experimental release).</p>
<p><strong>2023-Apr-17</strong> - Official start of this Fork.</p>

<div class="separator" id="overview"></div>

<h2>Overview</h2>
<p><strong>To be clear</strong>, it is not my intent to take over the Bochs project, but to merely add extensive USB function, debugging, and logging to the existing Bochs project, through <a href="https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork">Pull Requests</a>.</p>
<p>If you would like to integrate my current USB source into your Bochs Project, you can visit my fork's source tree at <a href="https://github.com/fysnet/Bochs-USB-Edition">https://github.com/fysnet/Bochs-USB-Edition</a>.</p>
<p>If you do not have the capabilities to build the project, I have Windows versions of the executables in my <a href="downloads.php">Downloads</a> section. (See the 'Notes' section below)</p>
<p>A copy of the <a href="user/index.html">User Documentation</a> is compiled from the <a href="https://github.com/bochs-emu/Bochs/tree/master/bochs/doc/docbook">Official Bochs User.dbk file</a>.</p>
<p>If you have any questions or comments, please contact me at: fys [at] fysnet [dot] net.</p>

<div class="separator" id="notes"></div>

<h2>Notes</h2>
<p>My build platform and my target platform are both for Windows 10. I do not have a Linux or *unix environment and will not have binaries for Linux. However, I will try to keep the source portable so that it can be built for a Linux environment with little to no modifications. If you build my source for a Linux environment, and wish to share the binary, please let me know.</p>
</div>

</body>
</html>

