# A 部分：网站框架与整合

这份可运行的整合版已接入队友的两张图，保留原网站结构和深蓝白样式。可以发给组员继续检查和部署。

## 你负责的文件

- `app.R`：网站入口、顶部标题、五个标签页、首页、公共筛选与各模块的连接。
- `www/styles.css`：全站颜色、字体、间距、卡片、按钮和手机布局。
- `www/favicon.svg`：网站小图标。
- `R/config.R`：标题、组名、学期、数据路径、可选人口学字段和图表配色。

网站使用英语呈现课程研究。风格为深蓝白配色和衬线标题，没有使用老师示例网站作为模板。首页按最新反馈删除顶部横条、标题下的介绍和按钮、右侧问题导航及统计卡片行，主图铺满内容区域。

## 怎么开始看

在 RStudio 中打开这个文件夹，将它设为工作目录。首次运行 `source("install_packages.R")`，之后打开 `app.R`，点击 **Run App**。也可以运行 `source("launch_app.R")`。

不要直接双击 `app.R` 后期待它像 HTML 一样打开；它需要 R Shiny 服务。整份项目里的 `R`、`www`、`data` 文件夹需要一起保留。

## 现有五个标签页

1. **Overview**：编号 01，与其他标签页共用标题和图表样式。图下的解读随左侧筛选更新，显示当前最常见的回答及其人数和占比。
2. **Tools & tasks**：队友的 Figure 1，按学术用途显示主要 AI 工具的堆叠条形图，可切换用途和人数/百分比。
3. **Time & future choices**：队友的 Figure 2，每周使用时长直方图。用左栏 **Future tool choice** 筛选 All、Stay 或 Switch。图内可切换频数和密度，调整分箱宽度和 X 轴范围。勾选手动设置 Y 轴后，用滑条调整上限。
4. **The study**：D 的 Summary of Findings。包含调查概况、方法、每周使用时长摘要、统计结果和研究局限。摘要表和统计结果随左侧筛选更新。
5. **Data explorer**：E/整合位置。当前筛选下的可搜索、排序表格。

左侧筛选对所有页面共用。两张图都使用同一个筛选样本；Figure 1 为了计算某用途内选定工具的占比，用筛选工具前的该用途 AI 使用者人数作分母。其他全站筛选仍参与分母计算。

两张图共用侧栏的 **Chart palette (both figures)** 菜单。默认深蓝，另外可选灰阶和柔和色。切换标签页会沿用已选配色。

## 给组员的最小交接约定

- B 主要改 `R/tools_B.R`，保留 `toolsUI(id, survey)` 和 `toolsServer(id, data, before_tool, palette)`。
- C 主要改 `R/usage_C.R`，保留 `usageUI(id, data)` 和 `usageServer(id, data, palette)`。
- D 主要改 `R/study_D.R`，保留 `studyUI(id)` 和 `studyServer(id, data, centre)`。
- E 主要改 `R/filters_E.R` 并负责 GitHub、依赖文件、Posit Connect Cloud、最终 README 公共链接。
- 模块里的输入/输出 ID 使用 `NS(id)`。服务器里的数据通过 `data()` 读取，保持联动。
- Figure 1 和 2 的配色放在 `R/config.R` 的 `FIGURE_PALETTES`，由 A 统一维护。
- A 最后将上述模块放回同一文件夹，启动一次完整网站，再逐一点击每个控件。

## TA 已同意的筛选替代方案

根据队友提供的 TA 回复，这个项目可用 **Primary AI tool（主要 AI 工具）** 作为原人口学筛选要求的替代。它是问卷中的类别变量，可以用来联动两张图和数据表。

抽样方式沿用你最新确认的 **volunteer sampling（自愿应答抽样）**。网站已说明自选择偏差、代表性限制和探索性解释，不再使用 SRS。

## 最后提交前

- B/C/D 的说明与最终分析保持一致；筛选后更新分母，零条数据时显示提示。
- 检查 TA 同意的主要 AI 工具筛选，以及人数、百分比和无数据状态。
- E 按 README 在 **Posit Connect Cloud** 上线，公开 GitHub 源文件，并用未登录的新浏览器检查链接。
- README 中写真实的公共地址。`127.0.0.1` 只在当前电脑可用，不能用作作业提交链接。
- 数据副本已去掉课程专用 ID；公开仓库只放本项目的数据文件，不要误放之前带 ID 的原 CSV。
