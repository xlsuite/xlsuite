require File.dirname(__FILE__) + '/../test_helper'
require 'net/pop3'
require 'email_account'
require 'pop3_email_account'

class EmailAccountTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @emails = Email.count
    @recipients = Recipient.count

    Net::POP3.instance = @server = Net::POP3.new
  end

  context "An EmailAccount connected to mail.rickstonehouse.com on port 213, with username 'rick' and password 'garble'" do
    setup do
      @eaccount = Pop3EmailAccount.create!(
        :name => 'Rick', :server => 'mail.rickstonehouse.com', :port => 213, :username => 'rick',
        :password => 'garble', :account => Account.find(:first), :party => parties(:bob))
      @eaccount.retrieve!
    end

    should "connect to mail.rickstonehouse.com" do
      assert_equal "mail.rickstonehouse.com", @server.address
    end
    
    should "connect to port 213" do
      assert_equal 213, @server.port
    end

    should "authenticate with 'rick'" do
      assert_equal "rick", @server.account
    end

    should "authenticate with 'garble'" do
      assert_equal "garble", @server.password
    end

    context "with 1 mail in the mailbox" do
      setup do
        @message = Net::POPMail.new
        @message.pop = <<EOM
Return-Path: <drbrain@segment7.net>
Received: from mx4.internal (mx4.internal [10.202.2.203])
	 by server4.messagingengine.com (Cyrus v2.3-alpha) with LMTPA;
	 Wed, 19 Apr 2006 13:12:16 -0400
X-Sieve: CMU Sieve 2.3
X-Spam-score: 0.0
X-Spam-hits: BAYES_00
X-Resolved-to: fbeausoleil@ftml.net
X-Delivered-to: francois@teksol.info
X-Mail-from: drbrain@segment7.net
Received: from toxic.magnesium.net (toxic.magnesium.net [207.154.84.15])
	by mx4.messagingengine.com (Postfix) with ESMTP id 536F1FBFA
	for <francois@teksol.info>; Wed, 19 Apr 2006 13:11:49 -0400 (EDT)
Received: from [192.168.1.70] (coop.robotcoop.com [216.231.59.167])
	by toxic.magnesium.net (Postfix) with ESMTP id 2913EDA871
	for <francois@teksol.info>; Wed, 19 Apr 2006 10:12:14 -0700 (PDT)
Mime-Version: 1.0 (Apple Message framework v749.3)
In-Reply-To: <44464ACA.9040406@teksol.info>
References: <44464ACA.9040406@teksol.info>
Content-Type: text/plain; charset=ISO-8859-1; delsp=yes; format=flowed
Message-Id: <CFD2A945-D163-403E-9DE7-EDC131CC61C8@segment7.net>
Content-Transfer-Encoding: quoted-printable
From: Eric Hodel <drbrain@segment7.net>
Subject: Re: About speeding up rails testing on Windows
Date: Wed, 19 Apr 2006 10:12:09 -0700
To: =?ISO-8859-1?Q?Fran=E7ois_Beausoleil?= <francois@teksol.info>
X-Mailer: Apple Mail (2.749.3)

Yeah, you know, really speed it up !
--
Eric
EOM

        @server.mails = [@message]
        @eaccount.retrieve!
      end

      should "retrieve 1 email" do
        assert_equal 1, Email.count - @emails
      end
    end

    context "with 2 mails in the mailbox" do
      setup do
        @message0 = Net::POPMail.new
        @message0.pop = <<EOM
Return-Path: <drbrain@segment7.net>
Received: from mx4.internal (mx4.internal [10.202.2.203])
	 by server4.messagingengine.com (Cyrus v2.3-alpha) with LMTPA;
	 Wed, 19 Apr 2006 13:12:16 -0400
X-Sieve: CMU Sieve 2.3
X-Spam-score: 0.0
X-Spam-hits: BAYES_00
X-Resolved-to: fbeausoleil@ftml.net
X-Delivered-to: francois@teksol.info
X-Mail-from: drbrain@segment7.net
Received: from toxic.magnesium.net (toxic.magnesium.net [207.154.84.15])
	by mx4.messagingengine.com (Postfix) with ESMTP id 536F1FBFA
	for <francois@teksol.info>; Wed, 19 Apr 2006 13:11:49 -0400 (EDT)
Received: from [192.168.1.70] (coop.robotcoop.com [216.231.59.167])
	by toxic.magnesium.net (Postfix) with ESMTP id 2913EDA871
	for <francois@teksol.info>; Wed, 19 Apr 2006 10:12:14 -0700 (PDT)
Mime-Version: 1.0 (Apple Message framework v749.3)
In-Reply-To: <44464ACA.9040406@teksol.info>
References: <44464ACA.9040406@teksol.info>
Content-Type: text/plain; charset=ISO-8859-1; delsp=yes; format=flowed
Message-Id: <CFD2A945-D163-403E-9DE7-EDC131CC61C8@segment7.net>
Content-Transfer-Encoding: quoted-printable
From: Eric Hodel <drbrain@segment7.net>
Subject: Re: About speeding up rails testing on Windows
Date: Wed, 19 Apr 2006 10:12:09 -0700
To: =?ISO-8859-1?Q?Fran=E7ois_Beausoleil?= <francois@teksol.info>
X-Mailer: Apple Mail (2.749.3)

Yeah, you know, really speed it up !
--
Eric
EOM

        @message1 = Net::POPMail.new
        @message1.pop = <<EOM
Return-Path: <drbrain@segment7.net>
Received: from mx4.internal (mx4.internal [10.202.2.203])
	 by server4.messagingengine.com (Cyrus v2.3-alpha) with LMTPA;
	 Wed, 19 Apr 2006 13:12:16 -0400
X-Sieve: CMU Sieve 2.3
X-Spam-score: 0.0
X-Spam-hits: BAYES_00
X-Resolved-to: fbeausoleil@ftml.net
X-Delivered-to: francois@teksol.info
X-Mail-from: drbrain@segment7.net
Received: from toxic.magnesium.net (toxic.magnesium.net [207.154.84.15])
	by mx4.messagingengine.com (Postfix) with ESMTP id 536F1FBFA
	for <francois@teksol.info>; Wed, 19 Apr 2006 13:11:49 -0400 (EDT)
Received: from [192.168.1.70] (coop.robotcoop.com [216.231.59.167])
	by toxic.magnesium.net (Postfix) with ESMTP id 2913EDA871
	for <francois@teksol.info>; Wed, 19 Apr 2006 10:12:14 -0700 (PDT)
Mime-Version: 1.0 (Apple Message framework v749.3)
In-Reply-To: <44464ACA.9040406@teksol.info>
References: <44464ACA.9040406@teksol.info>
Content-Type: text/plain; charset=ISO-8859-1; delsp=yes; format=flowed
Message-Id: <BFD2A945-D163-403E-9DE7-EDC131CC61C8@segment7.net>
Content-Transfer-Encoding: quoted-printable
From: Eric Hodel <drbrain@segment7.net>
Subject: Re: About speeding up rails testing on Windows
Date: Wed, 19 Apr 2006 10:12:09 -0700
To: =?ISO-8859-1?Q?Fran=E7ois_Beausoleil?= <francois@teksol.info>
X-Mailer: Apple Mail (2.749.3)

Real speed daemon, this guy !
--
Eric
EOM

        @server.mails = [@message0, @message1]
      end

      should "retrieve 2 mails" do
        @eaccount.retrieve!
        assert_equal 2, Email.count - @emails
      end

      should "ignore already imported mail" do
        @eaccount.retrieve! # Do it once...
        @eaccount.retrieve! # Do it twice
        assert_equal 2, Email.count - @emails, "Should have imported the 2 mail messages only once"
      end

      should "ignore errors while retrieving one mail and go on with the next message" do
        class << @message0
          def pop
            raise Net::POPError
          end
        end

        @eaccount.retrieve!
        assert_equal 1, Email.count - @emails
      end

      should "reraise Net::POPError when that is what the initial connection to the server generates" do
        @server.fail_on_start = true
        assert_raise Net::POPError do
          @eaccount.retrieve!
        end
      end

      context "with a mail from Francois bcc to Harman" do
        setup do
          @message = Net::POPMail.new
          @server.mails = [@message]
        end

        context "having a X-Original-To field" do
          setup do
            @message.pop = <<EOM
Return-Path: <hsandjaja@xlsuite.com>
X-Original-To: hsandjaja@xltester.com
Delivered-To: m7438751@spunkymail-mx1.g.dreamhost.com
Received: from py-out-1112.google.com (py-out-1112.google.com [64.233.166.181])
     by spunkymail-mx1.g.dreamhost.com (Postfix) with ESMTP id 6D800FA158
     for <hsandjaja@xltester.com>; Wed, 22 Aug 2007 13:45:21 -0700 (PDT)
Received: by py-out-1112.google.com with SMTP id u52so588432pyb
     for <hsandjaja@xltester.com>; Wed, 22 Aug 2007 13:45:27 -0700 (PDT)
Received: by 10.64.193.2 with SMTP id q2mr1778862qbf.1187815526626;
     Wed, 22 Aug 2007 13:45:26 -0700 (PDT)
Received: by 10.65.244.8 with HTTP; Wed, 22 Aug 2007 13:45:26 -0700 (PDT)
Message-ID: <c3ba69710708221345h74cc0491ycffe90c8de243f6f@mail.gmail.com>
Date: Wed, 22 Aug 2007 13:45:26 -0700
From: "Harman Sandjaja" <hsandjaja@xlsuite.com>
Subject: BCC only
MIME-Version: 1.0
Content-Type: multipart/alternative;
     boundary="----=_Part_137941_2523447.1187815526592"
To: undisclosed-recipients:;
EOM

            @eaccount.retrieve!
            @email = Email.find(:first, :order => "id DESC")
          end

          should "deliver to Harman" do
            assert_equal %w(hsandjaja@xltester.com), @email.bccs.map(&:address)
          end

          should "be from Francois" do
            assert_equal "hsandjaja@xlsuite.com", @email.sender.address
          end

          should "have only 1 Bcc recipient" do
            assert_equal 1, @email.bccs.count, @email.bccs.map(&:address).inspect
          end
        end

        context "having a Delivered-To field" do
          setup do
            @message.pop = <<EOM
Delivered-To: hsandjaja@xlsuite.com
Received: by 10.65.244.8 with SMTP id w8cs769837qbr;
        Wed, 22 Aug 2007 13:32:22 -0700 (PDT)
Received: by 10.64.251.9 with SMTP id y9mr1755623qbh.1187814741956;
        Wed, 22 Aug 2007 13:32:21 -0700 (PDT)
Return-Path: <francois@teksol.info>
Received: from relais.videotron.ca (relais.videotron.ca [24.201.245.36])
        by mx.google.com with ESMTP id c5si521942qbc.2007.08.22.13.32.21;
        Wed, 22 Aug 2007 13:32:21 -0700 (PDT)
Received-SPF: pass (google.com: domain of francois@teksol.info designates 24.201.245.36 as permitted sender) client-ip=24.201.245.36;
Authentication-Results: mx.google.com; spf=pass (google.com: domain of francois@teksol.info designates 24.201.245.36 as permitted sender) smtp.mail=francois@teksol.info
Received: from [127.0.0.1] ([24.37.105.58]) by VL-MH-MR002.ip.videotron.ca
 (Sun Java System Messaging Server 6.2-2.05 (built Apr 28 2005))
 with ESMTP id <0JN6005DKZPK0SE0@VL-MH-MR002.ip.videotron.ca> for
 hsandjaja@xlsuite.com; Wed, 22 Aug 2007 16:32:21 -0400 (EDT)
Date: Wed, 22 Aug 2007 16:33:37 -0400
From: =?UTF-8?B?RnJhbsOnb2lzIEJlYXVzb2xlaWw=?= <francois@teksol.info>
Subject: test bcc
To: =?UTF-8?B?77+9?= <francois.beausoleil@gmail.com>
Message-id: <46CC9DA1.3090207@teksol.info>
Organization: Solutions Technologiques Internationales
MIME-version: 1.0
Content-type: text/plain; charset=UTF-8; format=flowed
Content-transfer-encoding: 7BIT
User-Agent: Thunderbird 2.0.0.6 (Windows/20070728)

test bcc
EOM

            @eaccount.retrieve!
            @email = Email.find(:first, :order => "id DESC")
          end

          should "deliver to Harman" do
            assert_equal %w(hsandjaja@xlsuite.com), @email.bccs.map(&:address)
          end

          should "be from Francois" do
            assert_equal "francois@teksol.info", @email.sender.address
          end

          should "have only 1 Bcc recipient" do
            assert_equal 1, @email.bccs.count, @email.bccs.map(&:address).inspect
          end

          should "record the original recipient (which is Francois)" do
            assert_equal %w(francois.beausoleil@gmail.com), @email.tos.map(&:address)
          end
        end
      end
    end
  end
end
