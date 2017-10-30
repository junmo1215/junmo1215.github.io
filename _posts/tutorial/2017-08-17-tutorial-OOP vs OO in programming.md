---
date: 2017-8-17 11:23
status: public
title: '[教程]物件導向和程序導向'
layout: post
tag: [教程]
categories: [tutorial]
description: 
---


[TOC]

# 说明

這個算是一篇不太專業的科普文，目的是幫助很多初學程式的人了解物件導向和程序導向的區別。像我大學初學程式的時候老師教的第一門課是C++，然後老師上課就開始強調C++是物件導向的語言，而C語言是程序導向，一定要弄清楚其中的區別，然而當時大家都聽不太明白，因為初學的時候連class都沒有接觸，完全不懂其中的差別，直到學完這門課程都只了解到C++有class的概念，c語言沒有。直到後來學習一個公開課的時候才逐漸明白區別在哪，現在程式寫的越來越多也逐漸有了一些清晰的認識，加上身邊剛好有小夥伴需要，所以打算寫這篇不太靠譜的入門教程，幫助大家有一個基本的認識。

這篇文章不會寫的很詳細，也不會詳細定義一些物件導向中的術語（比如**多型(Polymorphism)**和**繼承(Inheritance)**等）。所以看完這篇教程只能有個大概的認識，如果看完這篇文章之後能看明白更專業的書籍，這篇文章的目的就達到了。

> 其實我個人不建議剛學程式就開始了解這些基礎概念，我當時學的時候一度打消了學習的積極性，太多的基礎概念直接強行灌輸到大腦里並沒有什麼用，我覺得這個應該在用多了之後，需要使用到這方面知識再自己慢慢去了解要好一些。這也是現在很多老師教初學者的時候選擇使用Python等腳本語言的原因，但是還是有好多老師會開始就放上這些概念。如果是感興趣自學程式的話推薦斯坦福大學的編程方法學，百度或Google一下很容易搜到（但是我是很多年前看的，現在不知道還有沒有開課，視頻倒是有很多）。

# 動機

物件導向其實只是一種編程思想，與所使用的語言關係不大。雖然物件導向出現的比較晚，但是並不代表就要高級一些，只是說這個設計模式適應了潮流，在複雜一些的軟體中，尤其是多個不同模塊之間相互連接（比如界面的設計），物件導向是必不可少的。

# 實例

直接用一個例子來說明區別：假設要設計一個系統，能滿足一個人在一個ATM機裡面取錢，並且能方便的知道賬戶和ATM機中有多少餘額，使用Python來實現這個功能。

程序導向模式的實現：

``` python
# coding = UTF-8

def main():
    user_cash = 0
    atm_account = 10000

    print("現金:{:.2f}, ATM機餘額:{:.2f}".format(user_cash, atm_account))
    while True:
        input_value = input('請輸入取款金額：')
        withdrawal_amount, is_end = parse(input_value)

        if is_end:
            break

        if withdrawal_amount > atm_account:
        	print("取款金額超過ATM機餘額")
        else:
            user_cash += withdrawal_amount
            atm_account -= withdrawal_amount
        print("現金:{:.2f}, ATM機餘額:{:.2f}".format(user_cash, atm_account))
        print("")

def parse(input_value):
    is_end = False
    withdrawal_amount = 0
    try:
        withdrawal_amount = float(input_value)
        if withdrawal_amount < 0:
            is_end = True
    except:
        is_end = True
    return withdrawal_amount, is_end

if __name__ == '__main__':
    main()

```

物件導向方式的實現：

``` python
# coding = UTF-8

class User(object):
    def __init__(self, cash):
        self.cash = cash

    def withdraw_money(self, withdrawal_amount, atm):
        if withdrawal_amount > atm.account:
            print("取款金額超過ATM機餘額")
            return

        self.cash += withdrawal_amount
        atm.account -= withdrawal_amount

class Atm(object):
    def __init__(self, account):
        self.account = account

def main():
    user = User(0)
    atm = Atm(10000)

    print("現金:{:.2f}, ATM機餘額:{:.2f}".format(user.cash, atm.account))
    while True:
        input_value = input('請輸入取款金額：')
        withdrawal_amount, is_end = parse(input_value)
        if is_end:
            break

        user.withdraw_money(withdrawal_amount, atm)
        print("現金:{:.2f}, ATM機餘額:{:.2f}".format(user.cash, atm.account))
        print("")

def parse(input_value):
    is_end = False
    withdrawal_amount = 0
    try:
        withdrawal_amount = float(input_value)
        if withdrawal_amount < 0:
            is_end = True
    except:
        is_end = True
    return withdrawal_amount, is_end

if __name__ == '__main__':
    main()

```

對比兩種實現，雖然物件導向的code要長一些，但是main裡面的思路更加清晰，並且物件導向的code更加容易擴展，這是我認為物件導向最重要的地方。

到這裡還看不出來物件導向優勢在哪，但是發現按照上面的code很多人會一次把ATM機清空，然而實際生活中並不會這樣，因為實際生活中每個用戶在銀行裡面都有一個賬戶，取錢是不能超過賬戶餘額的，所以我們也要加上這個限制。這時候就需要讀懂之前的code然後做更改，尤其是程式複雜一些，加上當時可能會由於很多奇怪的原因有好多看不懂的邏輯，看懂別人的code一般來講是一件很痛苦的事情。如果是程序導向的設計，我們需要看懂整個main函數的邏輯，但是對於物件導向設計，我的思路是用戶加一個賬戶顯然就是在User裡面加上一個字段，然後在取錢的方法裡面加上一個限制，對於main裡面的邏輯反而不太重視，只需要找到在哪裡定義了User類的實例就行。

> 對於print中的內容，其實物件導向的寫法有辦法可以不修改

附上兩種實現模式下代碼修改點：

程序導向：

![diff_in_pp](http://7xrop1.com1.z0.glb.clouddn.com/others/diff_in_pp.jpg)

物件導向：

![diff_in_oop](http://7xrop1.com1.z0.glb.clouddn.com/others/diff_in_oop.jpg)

在這裡可能還看不出物件導向的優勢，是因為目前來說只用到了物件導向的一個特性就是**封裝(Encapsulation)**，並且沒有發揮到優勢的地方。現在做進一步的改進理解封裝的優勢。

# 封裝(Encapsulation)

之前的例子只有一個ATM機以及一個用戶的情況，所以使用物件導向顯得畫蛇添足，但是現實生活中往往會有很多的atm機以及用戶，假設有兩個用戶在兩個ATM機裡面取錢，這就能體現出物件導向的優勢了。

兩種不同的實現方式如下

> 這裡的程序導向沒有使用最好的方式實現，所以code顯得比較複雜，其實可以使用類似字典或者C語言中結構體等方法完成，但是這些設計也有些像物件導向了，所以為了區別兩種不同模式，採用了比較極端一些的方法

過程導向：

``` python
# coding = UTF-8

def main():
    global alice_cash, alice_account, bob_cash, bob_account, icbc_atm_account, cmb_atm_account
    alice_cash = 0
    alice_account = 5000
    bob_cash = 200
    bob_account = 4000

    icbc_atm_account = 10000
    cmb_atm_account = 20000

    print(detail_message())
    while True:
        # 這裡存在一個變數裡面，防止後續取款的函數裡面有太多的判斷
        # 可以嘗試一下其他寫法
        user_name = get_user_name()
        if user_name == 'alice':
            user_cash = alice_cash
            user_account = alice_account
        elif user_name == 'bob':
            user_cash = bob_cash
            user_account = bob_account

        atm_name = get_atm_name()
        if atm_name == 'icbc':
            atm_account = icbc_atm_account
        elif atm_name == 'cmb':
            atm_account = cmb_atm_account

        input_value = input('請輸入取款金額：')
        withdrawal_amount, is_end = parse(input_value)

        if is_end:
            break

        if withdrawal_amount > atm_account:
        	print("取款金額超過ATM機餘額")
        elif withdrawal_amount > user_account:
            print("取款金額超過賬戶餘額")
        else:
            user_cash += withdrawal_amount
            user_account -= withdrawal_amount
            atm_account -= withdrawal_amount

        # 把臨時變數的值寫回真正的變數裡面
        if user_name == 'alice':
            alice_cash = user_cash
            alice_account = user_account
        elif user_name == 'bob':
            bob_cash = user_cash
            bob_account = user_account

        if atm_name == 'icbc':
            icbc_atm_account = atm_account
        elif atm_name == 'cmb':
            cmb_atm_account = atm_account

        print(detail_message())
        print("")

def get_atm_name():
    prompt = '請輸入取款的ATM機(icbc: 工商銀行, cmb: 招商銀行)：'
    atm_name = ""
    while atm_name == "":
        user_input = input(prompt).lower()
        if user_input in ['icbc', 'cmb']:
            atm_name = user_input
        else:
            atm_name = ""
    return atm_name

def get_user_name():
    prompt = '請輸入需要取款的用戶(A: alice, B: bob)：'
    user_name = ''
    while user_name == '':
        user_input = input(prompt).upper()
        if user_input == 'A':
            user_name = 'alice'
        elif user_input == 'B':
            user_name = 'bob'
        else:
            user_name = ''
    return user_name

def detail_message():
    return """
alice賬戶明細：
    現金：{:.2f}, 賬戶餘額：{:.2f}
bob賬戶明細：
    現金：{:.2f}, 賬戶餘額：{:.2f}
ATM機餘額：
    工商銀行：{:.2f}
    招商銀行：{:.2f}
""".format(alice_cash, alice_account, bob_cash, bob_account, icbc_atm_account, cmb_atm_account)

def parse(input_value):
    is_end = False
    withdrawal_amount = 0
    try:
        withdrawal_amount = float(input_value)
        if withdrawal_amount < 0:
            is_end = True
    except:
        is_end = True
    return withdrawal_amount, is_end

if __name__ == '__main__':
    main()

```

物件導向：

``` python
# coding = UTF-8

class User(object):
    def __init__(self, cash, account):
        self.cash = cash
        self.account = account

    def withdraw_money(self, withdrawal_amount, atm):
        if withdrawal_amount > atm.account:
            print("取款金額超過ATM機餘額")
            return
        elif withdrawal_amount > self.account:
            print("取款金額超過賬戶餘額")
            return

        self.cash += withdrawal_amount
        self.account -= withdrawal_amount
        atm.account -= withdrawal_amount
    
    def __str__(self):
        return "現金：{:.2f}, 賬戶餘額：{:.2f}".format(self.cash, self.account)

class Atm(object):
    def __init__(self, account):
        self.account = account

    def __str__(self):
        return "{:.2f}".format(self.account)

def main():
    global alice, bob, icbc_atm, cmb_atm
    alice = User(0, 5000)
    bob = User(200, 4000)
    icbc_atm = Atm(10000)
    cmb_atm = Atm(20000)

    print(detail_message())
    while True:
        user = get_user()
        atm = get_atm()

        input_value = input('請輸入取款金額：')
        withdrawal_amount, is_end = parse(input_value)
        if is_end:
            break

        user.withdraw_money(withdrawal_amount, atm)
        print(detail_message())

def get_atm():
    prompt = '請輸入取款的ATM機(icbc: 工商銀行, cmb: 招商銀行)：'
    atm = None
    while atm is None:
        user_input = input(prompt).upper()
        if user_input == 'ICBC':
            atm = icbc_atm
        elif user_input == 'CMB':
            atm = cmb_atm
        else:
            atm = None
    return atm

def get_user():
    prompt = '請輸入需要取款的用戶(A: alice, B: bob)：'
    user = None
    while user is None:
        user_input = input(prompt).upper()
        if user_input == 'A':
            user = alice
        elif user_input == 'B':
            user = bob
        else:
            user = None
    return user

def detail_message():
    return """
alice賬戶明細：
    {}
bob賬戶明細：
    {}
ATM機餘額：
    工商銀行：{}
    招商銀行：{}
""".format(alice, bob, icbc_atm, cmb_atm)

def parse(input_value):
    is_end = False
    withdrawal_amount = 0
    try:
        withdrawal_amount = float(input_value)
        if withdrawal_amount < 0:
            is_end = True
    except:
        is_end = True
    return withdrawal_amount, is_end

if __name__ == '__main__':
    main()

```

到這一步就能看出物件導向的優勢了，將同種類型的物件(User和Atm)封裝在一個抽象的class中，後面能直接通過定義的方式是構造class的實例，並且在需要使用物件屬性的時候也能很方便的調用。我覺得這樣做的最重要的好處是程式的邏輯清晰，方便以後擴展和修改，物件導向和程序導向我覺得是兩種不同的思維方式。

在物件導向中，我想的是用戶和ATM機都是物件，所以定義了這兩個class，然後在User可以取款，取款的時候需要用到取款金額和ATM機的實例，所以User類中的withdraw_money方法就能寫出來了（這裡也可以在ATM類裡面實現）。後面就是考慮整個流程了，定義兩個用戶，兩個ATM機，然後看是哪個用戶在哪個ATM機上取錢，輸出取錢之後的訊息等。在這個過程中如果需要的內容沒有提供需要去相應的class中實現，外面只負責調用而已，不過多的在外部實現class中應該實現的細節。

# 繼承(Inheritance)

除了思維方式的不同，物件導向還有一些其他的優勢。接著用實例簡單講下繼承，這部分用程序導向就不太好實現了，所以只附上物件導向的code。

前面有一個默認假設是銀行卡裡面錢不夠的時候是不能取錢的，假設現在有些用戶的卡是信用卡，在額度範圍內都能取現，所以現在要修改為在額度允許範圍內都能取現。因此我們有一個class繼承于之前的User，然後在原有基礎上增加額度的屬性，也就是初始化函數裡面除了調用User類的初始化方法外，再加上本身增加的這個屬性。重點要更改的邏輯是取款的這個方法有些變動，因此重新寫這個方法。

增加的code：

``` python
class CreditCardUser(User):
    def __init__(self, cash, account, credit_limit):
        super(CreditCardUser, self).__init__(cash, account)
        self.credit_limit = credit_limit

    def withdraw_money(self, withdrawal_amount, atm):
        if withdrawal_amount > atm.account:
            print("取款金額超過ATM機餘額")
            return
        elif withdrawal_amount > self.account + self.credit_limit:
            print("取款金額超過賬戶額度")
            return

        self.cash += withdrawal_amount
        self.account -= withdrawal_amount
        atm.account -= withdrawal_amount
```

然後只需要在main中把原先是User的人改為CreditCardUser就好：

``` python
# alice = User(0, 5000)
alice = CreditCardUser(0, 5000, 12000)
```

這裡CreditCardUser幾乎重寫了User類所有的方法，嚴格來講其實```__str__```方法也應該重寫，這裡為了表現子類可以直接調用父類的方法就沒有寫出來。雖然看上去繼承顯得很雞肋，但是使用繼承還是有必要的。

> 繼承的目的在於複用之前的邏輯，減少code的修改，所以在設計的時候就要想明白class應該怎樣設計，提供哪些方法，有哪些class繼承。像這樣比較清晰的或許一看就會很明白，但是對於比較抽象的物件就能難定義清晰，尤其是很多時候對於是否應該增加一個class都不太確定。所以個人覺得程式設計應該慢慢改善，畢竟寫好的程式不是一成不變的，之後別人或者自己更改程式碼的時候為了能快速定位好需要改變的地方，class的設計一定要清晰，並且需要留下設計文檔。總覺得寫一個能用的程式不難，但是寫好還是蠻難的。一般比較大型的軟體，尤其是維護了很久的那種，程式碼基本都不太能看。

# 多型(polymorphism)

其實上面的程式碼已經包含了多型的應用，由於我也沒有真正學習過程序導向是什麼，不確定沒有多型的編程是什麼樣子，這裡說說自己的理解。

上面的程式碼中定義了User和Atm這兩個不同的class，在調用這兩個class的初始化函數```__init__()```的時候，實現了兩種不同的效果，他們接收的參數不同，返回的物件也不同。之所以會達到這樣的效果就是由於多型這個機制的存在。

> 這個例子可能不是很嚴謹，因為init方法好像是繼承于object類的一個方法，不確定能不能算作是多型，我不太想糾結概念問題，只需要明白多型能讓不同class中調用相同的方法並且實現不同的效果就好了。

舉另外一個恰當點的例子，在Python語言中，數字和字串類型都可以做加法運算，但是操作數的類型是完全不一樣的，這就是由於多型機制中重載了 '+' 這個運算符。

# 最後

由於我自己也沒有很系統的學習過這些基礎知識，大部分地方都是只有自己的理解，加上上面的程式很多地方都不太嚴謹，也好多地方沒有用很好的寫法，所以科普文寫起來還是很虛，我比較喜歡的學習方式就是對比以及看程式碼，所以這篇文章也是適用於自己的風格，並不太適合所有人，只是希望有需要的話通過我這篇文章能有大概的印象，在之後看到其他的文章有更深刻的認識。

> 多說一點不相干的，如果只是感興趣自己寫程式寫著玩，我是不太建議了解這些概念的東西，雖然很多人覺得一開始有系統性的了解能避免走彎路，但是我覺得過於糾結這個反而喪失了寫程式的樂趣，自己寫著玩的程式差一點就差一點吧，之後重複的代碼太多改起來嘗到苦頭之後應該會自己慢慢摸索出一些道理，這時候去了解各種設計模式反而是最好的。但是如果是公司或者開源的團隊協作項目，還是要早早了解這些，遵循開發規範以免給別人留下大坑。

介紹了很多，說一下我對物件導向的理解，在大型軟體裡面，如果程式的架構非常清晰，開發的工程師實力很強的情況下，物件導向有很大的優勢，比如上面的程式裡面要想給用戶增加存錢的功能，只需要記得有這么一個class，然後找到User類並且給User類增加一個方法即可，繼承于User的CreditCardUser類直接可以使用這個方法，甚至不需要去讀懂其他部分的程式碼。所以修改的這個工程師就很容易就改完程式，然後簡單的測試一下新增的功能就能完成任務了（不過這個只是在理想狀態下）。

物件導向能方便的把一些功能模塊化，這樣方便在修改的時候快速定位到相關的程式碼，並且能方便的進行單元測試，在維護的過程中節省很多工作量。程序導向的優勢是寫起來比較簡單連貫，我自己平時寫一些簡單的腳本工具的時候都是程序導向的寫法，開發起來速度比較快，並且程式比較簡單的時候也比較容易定位問題在哪。這時候覺得強行使用物件導向有些過度設計了。所以這兩者只是不同的設計理念而已，與語言無關，需要看使用場景適合于那種方式。