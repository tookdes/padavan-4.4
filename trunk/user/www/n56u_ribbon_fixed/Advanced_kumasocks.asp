<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - KumaSocks 透明代理</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
	init_itoggle('kumasocks_enable', change_kumasocks_enable);
});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,21);
	show_footer();
	change_kumasocks_enable(1);
}

function applyRule(){
	if (!validForm())
		return false;

	showLoading();
	document.form.action_mode.value = " Restart ";
	document.form.current_page.value = "/Advanced_kumasocks.asp";
	document.form.next_page.value = "";
	document.form.action_script.value = "restart_kumasocks";
	document.form.submit();
}

function validForm(){
	if (document.form.kumasocks_enable[0].checked) {
		var socks5_addr = document.form.kumasocks_socks5_addr.value;
		var listen_port = document.form.kumasocks_listen_port.value;

		if (!socks5_addr.match(/^[A-Za-z0-9._-]+:[0-9]{1,5}$/)) {
			alert("SOCKS5 服务器地址格式错误");
			document.form.kumasocks_socks5_addr.focus();
			return false;
		}

		var socks5_port = parseInt(socks5_addr.replace(/^.*:/, ""), 10);
		if (socks5_port < 1 || socks5_port > 65535) {
			alert("SOCKS5 服务器端口范围应为 1-65535");
			document.form.kumasocks_socks5_addr.focus();
			return false;
		}

		if (!listen_port.match(/^[0-9]{1,5}$/) || parseInt(listen_port, 10) < 1 || parseInt(listen_port, 10) > 65535) {
			alert("本地监听端口范围应为 1-65535");
			document.form.kumasocks_listen_port.focus();
			return false;
		}
	}

	return true;
}

function done_validating(action){
	refreshpage();
}

function change_kumasocks_enable(mflag){
	var m = document.form.kumasocks_enable[0].checked;
	showhide_div("kumasocks_socks5_addr_tr", m);
	showhide_div("kumasocks_listen_port_tr", m);
	showhide_div("kumasocks_lan_only_tr", m);
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
	<div class="container-fluid" style="padding-right: 0px">
		<div class="row-fluid">
			<div class="span3"><center><div id="logo"></div></center></div>
			<div class="span9" >
				<div id="TopBanner"></div>
			</div>
		</div>
	</div>

	<div id="Loading" class="popup_bg"></div>

	<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

	<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

	<input type="hidden" name="current_page" value="Advanced_kumasocks.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="LANHostConfig;General;">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">

	<div class="container-fluid">
		<div class="row-fluid">
			<div class="span3">
				<div class="well sidebar-nav side_nav" style="padding: 0px;">
					<ul id="mainMenu" class="clearfix"></ul>
					<ul class="clearfix">
						<li>
							<div id="subMenu" class="accordion"></div>
						</li>
					</ul>
				</div>
			</div>

			<div class="span9">
				<div class="row-fluid">
					<div class="span12">
						<div class="box well grad_colour_dark_blue">
							<h2 class="box_head round_top"><#menu5_30#> - <#menu5_37#></h2>
							<div class="round_bottom">
							<div class="row-fluid">
								<div id="tabMenu" class="submenuBlock"></div>
								<div class="alert alert-info" style="margin: 10px;">KumaSocks 透明代理：局域网 TCP 流量通过 REDIRECT 转发到上游 SOCKS5 服务器。</div>
									</ul>
								</div>

								<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
									<tr>
										<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">启用 KumaSocks</a></th>
										<td style="border-top: 0 none;">
											<div class="main_itoggle">
												<div id="kumasocks_enable_on_of">
													<input type="checkbox" id="kumasocks_enable_fake" <% nvram_match_x("", "kumasocks_enable", "1", "value=1 checked"); %><% nvram_match_x("", "kumasocks_enable", "0", "value=0"); %>  />
												</div>
											</div>
											<div style="position: absolute; margin-left: -10000px;">
												<input type="radio" value="1" name="kumasocks_enable" id="kumasocks_enable_1" class="input" value="1" onClick="change_kumasocks_enable(1);" <% nvram_match_x("", "kumasocks_enable", "1", "checked"); %> /><#checkbox_Yes#>
												<input type="radio" value="0" name="kumasocks_enable" id="kumasocks_enable_0" class="input" value="0" onClick="change_kumasocks_enable(1);" <% nvram_match_x("", "kumasocks_enable", "0", "checked"); %> /><#checkbox_No#>
											</div>
										</td>
									</tr>
									<tr id="kumasocks_socks5_addr_tr" style="display:none;">
										<th width="30%" style="border-top: 0 none;">SOCKS5 服务器地址 :</th>
										<td style="border-top: 0 none;">
											<input type="text" maxlength="64" class="input" size="32" id="kumasocks_socks5_addr" name="kumasocks_socks5_addr" placeholder="192.168.1.100:1080" value="<% nvram_get_x("","kumasocks_socks5_addr"); %>" />
											<div> <span style="color:#888;">格式：IP:端口，如 192.168.1.100:1080</span></div>
										</td>
									</tr>
									<tr id="kumasocks_listen_port_tr" style="display:none;">
										<th width="30%" style="border-top: 0 none;">本地监听端口 :</th>
										<td style="border-top: 0 none;">
											<input type="text" maxlength="5" class="input" size="15" id="kumasocks_listen_port" name="kumasocks_listen_port" placeholder="1234" value="<% nvram_get_x("","kumasocks_listen_port"); %>" onkeypress="return is_number(this,event);" />
										</td>
									</tr>
									<tr id="kumasocks_lan_only_tr" style="display:none;">
										<th width="30%" style="border-top: 0 none;">仅代理 LAN 设备</th>
										<td style="border-top: 0 none;">
											<div class="main_itoggle">
												<div id="kumasocks_lan_only_on_of">
													<input type="checkbox" id="kumasocks_lan_only_fake" <% nvram_match_x("", "kumasocks_lan_only", "1", "value=1 checked"); %><% nvram_match_x("", "kumasocks_lan_only", "0", "value=0"); %>  />
												</div>
											</div>
											<div style="position: absolute; margin-left: -10000px;">
												<input type="radio" value="1" name="kumasocks_lan_only" id="kumasocks_lan_only_1" class="input" value="1" <% nvram_match_x("", "kumasocks_lan_only", "1", "checked"); %> /><#checkbox_Yes#>
												<input type="radio" value="0" name="kumasocks_lan_only" id="kumasocks_lan_only_0" class="input" value="0" <% nvram_match_x("", "kumasocks_lan_only", "0", "checked"); %> /><#checkbox_No#>
											</div>
											<div> <span style="color:#888;">推荐开启，避免路由器自身流量被重定向</span></div>
										</td>
									</tr>
									<tr>
										<td colspan="2" style="border-top: 0 none;">
											<center><input class="btn btn-primary" style="width: 219px" onclick="applyRule();" type="button" value="<#CTL_apply#>" /></center>
										</td>
									</tr>
								</table>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
	</form>

	<div id="footer"></div>
</div>
</body>
</html>
