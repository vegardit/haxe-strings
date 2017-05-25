/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package hx.strings.ansi;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:enum
abstract AnsiColor(Int) {
    var BLACK = 0;
    var RED = 1;
    var GREEN = 2;
    var YELLOW = 3;
    var BLUE = 4;
    var MAGENTA = 5;
    var CYAN = 6;
    var WHITE = 7;
    var DEFAULT = 9;
}
